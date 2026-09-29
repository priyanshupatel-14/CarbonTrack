package com.carbontrack.backend.verification;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

public class GeminiVisionApiClient implements VisionApiClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiVisionApiClient.class);
    private static final String DEFAULT_BASE_URL = "https://generativelanguage.googleapis.com";
    private static final String DEFAULT_MODEL = "gemini-3.5-flash-lite";

    private final String apiKey;
    private final String model;
    private final String baseUrl;
    private final int timeoutSeconds;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public GeminiVisionApiClient(String apiKey, String model, String baseUrl, int timeoutSeconds, ObjectMapper objectMapper) {
        this(apiKey, model, baseUrl, timeoutSeconds, objectMapper,
             HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(timeoutSeconds > 0 ? timeoutSeconds : 10)).build());
    }

    public GeminiVisionApiClient(String apiKey, String model, String baseUrl, int timeoutSeconds, ObjectMapper objectMapper, HttpClient httpClient) {
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.model = (model != null && !model.isBlank()) ? model.trim() : DEFAULT_MODEL;
        this.baseUrl = (baseUrl != null && !baseUrl.isBlank()) ? baseUrl.trim() : DEFAULT_BASE_URL;
        this.timeoutSeconds = timeoutSeconds > 0 ? timeoutSeconds : 10;
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
        this.httpClient = httpClient;
    }

    @Override
    public String getProviderName() {
        return "gemini";
    }

    @Override
    public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception {
        if (apiKey.isBlank()) {
            throw new IllegalStateException("Gemini API key is not configured.");
        }
        if (imageBytes == null || imageBytes.length == 0) {
            throw new IllegalArgumentException("Image content cannot be empty.");
        }

        String effectiveMimeType = (mimeType != null && !mimeType.isBlank()) ? mimeType : "image/jpeg";
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);

        String requestBody = buildRequestBody(prompt, effectiveMimeType, base64Image);

        // Security hardening: Authenticate via x-goog-api-key header instead of putting key in URL
        String requestUrl = baseUrl + "/v1beta/models/" + model + ":generateContent";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(requestUrl))
                .header("Content-Type", "application/json")
                .header("x-goog-api-key", apiKey)
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        log.debug("Sending vision request to Gemini API (model: {})", model);

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        int statusCode = response.statusCode();
        String responseBody = response.body();

        if (statusCode != 200) {
            log.warn("Gemini API returned error HTTP {}: {}", statusCode, sanitizeLog(responseBody));
            throw new IOException("Gemini API returned HTTP " + statusCode + ": " + sanitizeLog(responseBody));
        }

        return parseResponse(responseBody);
    }

    public String buildRequestBody(String prompt, String mimeType, String base64Image) {
        try {
            Map<String, Object> textPart = Map.of("text", prompt);
            Map<String, Object> inlineData = Map.of(
                    "mimeType", mimeType,
                    "data", base64Image
            );
            Map<String, Object> imagePart = Map.of("inlineData", inlineData);

            Map<String, Object> content = Map.of("parts", List.of(textPart, imagePart));
            Map<String, Object> generationConfig = Map.of(
                    "responseMimeType", "application/json",
                    "temperature", 0.1
            );

            Map<String, Object> root = Map.of(
                    "contents", List.of(content),
                    "generationConfig", generationConfig
            );

            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            throw new RuntimeException("Failed to serialize Gemini request payload", e);
        }
    }

    public VisionAnalysisResponse parseResponse(String jsonResponse) throws IOException {
        JsonNode root = objectMapper.readTree(jsonResponse);
        JsonNode candidates = root.path("candidates");
        if (!candidates.isArray() || candidates.isEmpty()) {
            throw new IOException("Gemini response contained no candidates.");
        }

        JsonNode firstCandidate = candidates.get(0);
        JsonNode parts = firstCandidate.path("content").path("parts");
        if (!parts.isArray() || parts.isEmpty()) {
            throw new IOException("Gemini response contained no content parts.");
        }

        String rawText = parts.get(0).path("text").asText("");
        if (rawText.isBlank()) {
            throw new IOException("Gemini candidate text is empty.");
        }

        String cleanedJson = cleanJsonText(rawText);
        JsonNode resultNode = objectMapper.readTree(cleanedJson);

        boolean relevant = resultNode.path("relevant").asBoolean(false);
        double confidence = Math.min(1.0, Math.max(0.0, resultNode.path("confidence").asDouble(0.0)));
        String reasoning = resultNode.path("reasoning").asText("No reasoning provided");

        List<String> detectedElements = new ArrayList<>();
        JsonNode elementsNode = resultNode.path("detectedElements");
        if (elementsNode.isArray()) {
            for (JsonNode el : elementsNode) {
                if (!el.asText().isBlank()) {
                    detectedElements.add(el.asText().trim());
                }
            }
        }

        // Fraud & Authenticity Risk parsing
        String fraudRisk = resultNode.path("fraudRisk").asText("LOW").toUpperCase();
        if (!Set.of("LOW", "MEDIUM", "HIGH").contains(fraudRisk)) {
            fraudRisk = resultNode.path("suspicious").asBoolean(false) ? "HIGH" : "LOW";
        }

        boolean possibleAiGenerated = resultNode.path("possibleAiGenerated").asBoolean(false);
        boolean possibleManipulation = resultNode.path("possibleManipulation").asBoolean(false);
        boolean possibleRecapture = resultNode.path("possibleRecapture").asBoolean(false);
        boolean suspicious = resultNode.path("suspicious").asBoolean(false)
                || !"LOW".equalsIgnoreCase(fraudRisk)
                || possibleAiGenerated
                || possibleManipulation
                || possibleRecapture;

        List<String> fraudIndicators = new ArrayList<>();
        JsonNode indicatorsNode = resultNode.path("fraudIndicators");
        if (indicatorsNode.isArray()) {
            for (JsonNode ind : indicatorsNode) {
                if (!ind.asText().isBlank()) {
                    fraudIndicators.add(ind.asText().trim());
                }
            }
        }

        return new VisionAnalysisResponse(
                relevant,
                confidence,
                detectedElements,
                reasoning,
                fraudRisk,
                possibleAiGenerated,
                possibleManipulation,
                possibleRecapture,
                fraudIndicators,
                "gemini",
                model,
                cleanedJson
        );
    }

    private String cleanJsonText(String text) {
        String trimmed = text.trim();
        if (trimmed.startsWith("```json")) {
            trimmed = trimmed.substring(7);
        } else if (trimmed.startsWith("```")) {
            trimmed = trimmed.substring(3);
        }
        if (trimmed.endsWith("```")) {
            trimmed = trimmed.substring(0, trimmed.length() - 3);
        }
        return trimmed.trim();
    }

    private String sanitizeLog(String msg) {
        if (msg == null) return "";
        if (!apiKey.isBlank()) {
            return msg.replace(apiKey, "[REDACTED_API_KEY]");
        }
        return msg;
    }
}
