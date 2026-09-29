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

public class OpenAiVisionApiClient implements VisionApiClient {

    private static final Logger log = LoggerFactory.getLogger(OpenAiVisionApiClient.class);
    private static final String DEFAULT_URL = "https://api.openai.com/v1/chat/completions";

    private final String apiKey;
    private final String model;
    private final String endpointUrl;
    private final int timeoutSeconds;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public OpenAiVisionApiClient(String apiKey, String model, String baseUrl, int timeoutSeconds, ObjectMapper objectMapper) {
        this(apiKey, model, baseUrl, timeoutSeconds, objectMapper,
             HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(timeoutSeconds > 0 ? timeoutSeconds : 10)).build());
    }

    public OpenAiVisionApiClient(String apiKey, String model, String baseUrl, int timeoutSeconds, ObjectMapper objectMapper, HttpClient httpClient) {
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.model = (model != null && !model.isBlank()) ? model.trim() : "gpt-4o-mini";
        this.endpointUrl = (baseUrl != null && !baseUrl.isBlank()) ? baseUrl.trim() : DEFAULT_URL;
        this.timeoutSeconds = timeoutSeconds > 0 ? timeoutSeconds : 10;
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
        this.httpClient = httpClient;
    }

    @Override
    public String getProviderName() {
        return "openai";
    }

    @Override
    public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception {
        if (apiKey.isBlank()) {
            throw new IllegalStateException("OpenAI API key is not configured.");
        }
        if (imageBytes == null || imageBytes.length == 0) {
            throw new IllegalArgumentException("Image content cannot be empty.");
        }

        String effectiveMimeType = (mimeType != null && !mimeType.isBlank()) ? mimeType : "image/jpeg";
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);
        String dataUrl = "data:" + effectiveMimeType + ";base64," + base64Image;

        String requestBody = buildRequestBody(prompt, dataUrl);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(endpointUrl))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + apiKey)
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        log.debug("Sending vision request to OpenAI endpoint (model: {})", model);

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        int statusCode = response.statusCode();
        String responseBody = response.body();

        if (statusCode != 200) {
            log.warn("OpenAI API returned error HTTP {}: {}", statusCode, sanitizeLog(responseBody));
            throw new IOException("OpenAI API returned HTTP " + statusCode + ": " + sanitizeLog(responseBody));
        }

        return parseResponse(responseBody);
    }

    public String buildRequestBody(String prompt, String dataUrl) {
        try {
            Map<String, Object> textContent = Map.of("type", "text", "text", prompt);
            Map<String, Object> imageUrl = Map.of("url", dataUrl);
            Map<String, Object> imageContent = Map.of("type", "image_url", "image_url", imageUrl);

            Map<String, Object> userMessage = Map.of(
                    "role", "user",
                    "content", List.of(textContent, imageContent)
            );

            Map<String, Object> responseFormat = Map.of("type", "json_object");

            Map<String, Object> root = Map.of(
                    "model", model,
                    "messages", List.of(userMessage),
                    "response_format", responseFormat,
                    "temperature", 0.2
            );

            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            throw new RuntimeException("Failed to serialize OpenAI request payload", e);
        }
    }

    public VisionAnalysisResponse parseResponse(String jsonResponse) throws IOException {
        JsonNode root = objectMapper.readTree(jsonResponse);
        JsonNode choices = root.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new IOException("OpenAI response contained no choices.");
        }

        JsonNode message = choices.get(0).path("message");
        String content = message.path("content").asText("");
        if (content.isBlank()) {
            throw new IOException("OpenAI choice message content is empty.");
        }

        String cleanedJson = cleanJsonText(content);
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

        String fraudRisk = resultNode.path("fraudRisk").asText("LOW").toUpperCase();
        if (!Set.of("LOW", "MEDIUM", "HIGH").contains(fraudRisk)) {
            fraudRisk = resultNode.path("suspicious").asBoolean(false) ? "HIGH" : "LOW";
        }

        boolean possibleAiGenerated = resultNode.path("possibleAiGenerated").asBoolean(false);
        boolean possibleManipulation = resultNode.path("possibleManipulation").asBoolean(false);
        boolean possibleRecapture = resultNode.path("possibleRecapture").asBoolean(false);

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
                "openai",
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
