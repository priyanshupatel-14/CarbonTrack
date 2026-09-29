package com.carbontrack.backend;

import com.carbontrack.backend.action.SustainableAction;
import com.carbontrack.backend.verification.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.net.http.HttpTimeoutException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class AiEvidenceAnalyzerTests {

    private MockVisionApiClient mockVisionClient;
    private AiEvidenceAnalyzer analyzer;
    private SustainableAction cyclingAction;
    private Path tempImageFile;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() throws IOException {
        mockVisionClient = new MockVisionApiClient();
        analyzer = new AiEvidenceAnalyzer(mockVisionClient, 0.70);
        objectMapper = new ObjectMapper();

        cyclingAction = new SustainableAction();
        cyclingAction.setTitle("Cycling to College");
        cyclingAction.setCategory("TRANSPORTATION");
        cyclingAction.setDescription("Commute using a bicycle.");
        cyclingAction.setEvidenceRequirements("Clear photo of bicycle parked on campus.");

        // Create a temporary valid image file for tests
        tempImageFile = Files.createTempFile("test_evidence_", ".jpg");
        Files.write(tempImageFile, new byte[]{ (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00, 0x11, 0x22 });
    }

    private Evidence createPhotoEvidence(Path path) {
        Evidence evidence = new Evidence();
        evidence.setId(UUID.randomUUID());
        evidence.setType(EvidenceType.PHOTO);
        evidence.setMimeType("image/jpeg");
        evidence.setStorageKey(path.toAbsolutePath().toString());
        return evidence;
    }

    @Test
    void testValidRelevantAiResponse() {
        mockVisionClient.setReturnValid(true);
        mockVisionClient.setConfidence(0.92);
        mockVisionClient.setReasoning("Bicycle detected parked at campus rack.");
        mockVisionClient.setDetectedElements(List.of("bicycle", "bike rack", "campus pathway"));
        mockVisionClient.setSuspicious(false);
        mockVisionClient.setFraudRisk("LOW");

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertTrue(result.isValid());
        assertEquals(0.92, result.confidence(), 0.001);
        assertFalse(result.isSuspicious());
        assertEquals("LOW", result.fraudRisk());
        assertFalse(result.possibleAiGenerated());
        assertFalse(result.possibleManipulation());
        assertFalse(result.possibleRecapture());
        assertTrue(result.detectedElements().contains("bicycle"));
        assertEquals("Bicycle detected parked at campus rack.", result.explanation());
    }

    @Test
    void testIrrelevantEvidenceFails() {
        mockVisionClient.setReturnValid(false);
        mockVisionClient.setConfidence(0.85);
        mockVisionClient.setReasoning("Image depicts a slice of pizza, not a bicycle.");
        mockVisionClient.setDetectedElements(List.of("food", "pizza"));
        mockVisionClient.setSuspicious(false);

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertTrue(result.explanation().contains("not appear relevant"));
    }

    @Test
    void testLowConfidenceFailsThreshold() {
        mockVisionClient.setReturnValid(true);
        mockVisionClient.setConfidence(0.55); // Below threshold of 0.70
        mockVisionClient.setReasoning("Image is blurry; possible bicycle in background.");
        mockVisionClient.setDetectedElements(List.of("blurry object"));
        mockVisionClient.setSuspicious(false);

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertTrue(result.explanation().contains("below required threshold"));
    }

    @Test
    void testSuspiciousEvidenceFails() {
        mockVisionClient.setReturnValid(true);
        mockVisionClient.setConfidence(0.95);
        mockVisionClient.setReasoning("Image contains watermarks from a stock photo website.");
        mockVisionClient.setDetectedElements(List.of("bicycle", "shutterstock watermark"));
        mockVisionClient.setSuspicious(true);
        mockVisionClient.setFraudRisk("HIGH");
        mockVisionClient.setFraudIndicators(List.of("stock photo watermark"));

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertTrue(result.isSuspicious());
        assertTrue(result.explanation().contains("authenticity review"));
    }

    @Test
    void testPossibleAiGeneratedDetectedFails() {
        mockVisionClient.setReturnValid(true);
        mockVisionClient.setConfidence(0.88);
        mockVisionClient.setReasoning("Image contains unnatural diffusion textures and warped geometry.");
        mockVisionClient.setDetectedElements(List.of("bicycle"));
        mockVisionClient.setFraudRisk("HIGH");
        mockVisionClient.setPossibleAiGenerated(true);
        mockVisionClient.setFraudIndicators(List.of("unnatural textures", "warped geometry"));

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertTrue(result.isSuspicious());
        assertTrue(result.possibleAiGenerated());
        assertEquals("HIGH", result.fraudRisk());
        assertTrue(result.explanation().contains("authenticity review"));
    }

    @Test
    void testDigitalManipulationDetectedFails() {
        mockVisionClient.setReturnValid(true);
        mockVisionClient.setConfidence(0.84);
        mockVisionClient.setReasoning("Inconsistent shadows and cutout edges around bicycle.");
        mockVisionClient.setDetectedElements(List.of("bicycle", "edited boundary"));
        mockVisionClient.setFraudRisk("HIGH");
        mockVisionClient.setPossibleManipulation(true);
        mockVisionClient.setFraudIndicators(List.of("inconsistent shadows", "cutout edges"));

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertTrue(result.possibleManipulation());
        assertTrue(result.explanation().contains("authenticity review"));
    }

    @Test
    void testPhotoOfScreenRecaptureDetectedFails() {
        mockVisionClient.setReturnValid(true);
        mockVisionClient.setConfidence(0.90);
        mockVisionClient.setReasoning("Moiré pattern and LCD pixel grid detected indicating photo of computer monitor.");
        mockVisionClient.setDetectedElements(List.of("screen", "bicycle image"));
        mockVisionClient.setFraudRisk("HIGH");
        mockVisionClient.setPossibleRecapture(true);
        mockVisionClient.setFraudIndicators(List.of("moire pattern", "pixel grid"));

        Evidence evidence = createPhotoEvidence(tempImageFile);
        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertTrue(result.possibleRecapture());
        assertTrue(result.explanation().contains("authenticity review"));
    }

    @Test
    void testProviderTimeoutFailsSafely() {
        VisionApiClient timeoutClient = new VisionApiClient() {
            @Override
            public String getProviderName() { return "gemini"; }

            @Override
            public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception {
                throw new HttpTimeoutException("Connection timed out after 10000ms");
            }
        };

        AiEvidenceAnalyzer timeoutAnalyzer = new AiEvidenceAnalyzer(timeoutClient, 0.70);
        Evidence evidence = createPhotoEvidence(tempImageFile);

        EvidenceAnalyzer.AnalysisResult result = timeoutAnalyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertEquals(0.0, result.confidence());
        assertTrue(result.explanation().contains("timed out"));
    }

    @Test
    void testProviderHttpErrorFailsSafely() {
        VisionApiClient errorClient = new VisionApiClient() {
            @Override
            public String getProviderName() { return "openai"; }

            @Override
            public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception {
                throw new IOException("OpenAI API returned HTTP 500: Internal Server Error");
            }
        };

        AiEvidenceAnalyzer errorAnalyzer = new AiEvidenceAnalyzer(errorClient, 0.70);
        Evidence evidence = createPhotoEvidence(tempImageFile);

        EvidenceAnalyzer.AnalysisResult result = errorAnalyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertEquals(0.0, result.confidence());
        assertTrue(result.explanation().contains("unavailable or encountered an error"));
    }

    @Test
    void testProviderRateLimitFailsSafely() {
        VisionApiClient rateLimitClient = new VisionApiClient() {
            @Override
            public String getProviderName() { return "gemini"; }

            @Override
            public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception {
                throw new IOException("Gemini API returned HTTP 429: Resource has been exhausted");
            }
        };

        AiEvidenceAnalyzer rateLimitAnalyzer = new AiEvidenceAnalyzer(rateLimitClient, 0.70);
        Evidence evidence = createPhotoEvidence(tempImageFile);

        EvidenceAnalyzer.AnalysisResult result = rateLimitAnalyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertEquals(0.0, result.confidence());
        assertTrue(result.explanation().contains("unavailable or encountered an error"));
    }

    @Test
    void testMissingStorageFileFailsSafely() {
        Path nonExistentPath = Path.of("missing_directory_12345/non_existent_file.jpg");
        Evidence evidence = createPhotoEvidence(nonExistentPath);

        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(evidence, cyclingAction);

        assertFalse(result.isValid());
        assertEquals(0.0, result.confidence());
        assertTrue(result.explanation().contains("does not exist"));
    }

    @Test
    void testNonPhotoEvidenceRejectedForAi() {
        Evidence locEvidence = new Evidence();
        locEvidence.setId(UUID.randomUUID());
        locEvidence.setType(EvidenceType.LOCATION);

        EvidenceAnalyzer.AnalysisResult result = analyzer.analyze(locEvidence, cyclingAction);

        assertFalse(result.isValid());
        assertEquals("Non-photo evidence", result.detectedContent());
    }

    @Test
    void testDeduplicationCachingDoesNotCallProviderTwice() {
        final int[] callCount = {0};
        VisionApiClient countingClient = new VisionApiClient() {
            @Override
            public String getProviderName() { return "mock"; }

            @Override
            public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) {
                callCount[0]++;
                return new VisionAnalysisResponse(true, 0.90, List.of("bike"), "Valid", false, "mock", "v1");
            }
        };

        AiEvidenceAnalyzer cachedAnalyzer = new AiEvidenceAnalyzer(countingClient, 0.70);
        Evidence evidence = createPhotoEvidence(tempImageFile);

        // First call
        EvidenceAnalyzer.AnalysisResult res1 = cachedAnalyzer.analyze(evidence, cyclingAction);
        assertTrue(res1.isValid());
        assertEquals(1, callCount[0]);

        // Second call with same evidence
        EvidenceAnalyzer.AnalysisResult res2 = cachedAnalyzer.analyze(evidence, cyclingAction);
        assertTrue(res2.isValid());
        assertEquals(1, callCount[0]); // Cached! Provider was NOT called a second time
    }

    @Test
    void testPromptContainsActionContextAndAntiInjectionInstructions() {
        String prompt = analyzer.buildPrompt(cyclingAction);

        assertTrue(prompt.contains("<action_context>"));
        assertTrue(prompt.contains("Cycling to College"));
        assertTrue(prompt.contains("TRANSPORTATION"));
        assertTrue(prompt.contains("Commute using a bicycle."));
        assertTrue(prompt.contains("Clear photo of bicycle parked on campus."));
        assertTrue(prompt.contains("SECURITY & INTEGRITY INSTRUCTIONS"));
        assertTrue(prompt.contains("FRAUD / AUTHENTICITY RISK"));
        assertTrue(prompt.contains("fraudRisk"));
        assertTrue(prompt.contains("possibleAiGenerated"));
        // Ensure no user PII placeholders exist
        assertFalse(prompt.contains("student_id"));
        assertFalse(prompt.contains("email"));
        assertFalse(prompt.contains("password"));
    }

    @Test
    void testGeminiVisionApiClientParsesRealJsonCorrectly() throws Exception {
        GeminiVisionApiClient client = new GeminiVisionApiClient("fake-key", "gemini-3.5-flash-lite", "", 10, objectMapper);

        String sampleGeminiResponse = """
                {
                  "candidates": [
                    {
                      "content": {
                        "parts": [
                          {
                            "text": "{\\"relevant\\": true, \\"confidence\\": 0.94, \\"reasoning\\": \\"Clear photo of bicycle.\\", \\"detectedElements\\": [\\"bicycle\\", \\"campus\\"], \\"fraudRisk\\": \\"LOW\\", \\"possibleAiGenerated\\": false, \\"possibleManipulation\\": false, \\"possibleRecapture\\": false, \\"fraudIndicators\\": []}"
                          }
                        ]
                      }
                    }
                  ]
                }
                """;

        VisionAnalysisResponse resp = client.parseResponse(sampleGeminiResponse);

        assertTrue(resp.relevant());
        assertEquals(0.94, resp.confidence(), 0.001);
        assertEquals("Clear photo of bicycle.", resp.reasoning());
        assertEquals(List.of("bicycle", "campus"), resp.detectedElements());
        assertEquals("LOW", resp.fraudRisk());
        assertFalse(resp.possibleAiGenerated());
        assertFalse(resp.possibleManipulation());
        assertFalse(resp.possibleRecapture());
        assertFalse(resp.suspicious());
    }

    @Test
    void testGeminiVisionApiClientParsesFraudFlagsCorrectly() throws Exception {
        GeminiVisionApiClient client = new GeminiVisionApiClient("fake-key", "gemini-3.5-flash-lite", "", 10, objectMapper);

        String sampleGeminiResponse = """
                {
                  "candidates": [
                    {
                      "content": {
                        "parts": [
                          {
                            "text": "{\\"relevant\\": true, \\"confidence\\": 0.75, \\"reasoning\\": \\"AI generation artifacts visible.\\", \\"detectedElements\\": [\\"bicycle\\"], \\"fraudRisk\\": \\"HIGH\\", \\"possibleAiGenerated\\": true, \\"possibleManipulation\\": false, \\"possibleRecapture\\": false, \\"fraudIndicators\\": [\\"unnatural frame geometry\\"]}"
                          }
                        ]
                      }
                    }
                  ]
                }
                """;

        VisionAnalysisResponse resp = client.parseResponse(sampleGeminiResponse);

        assertTrue(resp.relevant());
        assertEquals(0.75, resp.confidence(), 0.001);
        assertEquals("HIGH", resp.fraudRisk());
        assertTrue(resp.possibleAiGenerated());
        assertTrue(resp.suspicious());
        assertEquals(List.of("unnatural frame geometry"), resp.fraudIndicators());
    }

    @Test
    void testGeminiVisionApiClientThrowsOnMalformedJson() {
        GeminiVisionApiClient client = new GeminiVisionApiClient("fake-key", "gemini-3.5-flash-lite", "", 10, objectMapper);

        String malformedResponse = """
                {
                  "candidates": [
                    {
                      "content": {
                        "parts": [
                          {
                            "text": "THIS IS NOT JSON AT ALL"
                          }
                        ]
                      }
                    }
                  ]
                }
                """;

        assertThrows(IOException.class, () -> client.parseResponse(malformedResponse));
    }
}
