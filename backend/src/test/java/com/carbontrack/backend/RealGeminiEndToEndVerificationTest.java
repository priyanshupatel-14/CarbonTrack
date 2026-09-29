package com.carbontrack.backend;

import com.carbontrack.backend.action.*;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.verification.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Testcontainers
@DirtiesContext
class RealGeminiEndToEndVerificationTest {

    private static final Logger log = LoggerFactory.getLogger(RealGeminiEndToEndVerificationTest.class);

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private VerificationResultRepository verificationResultRepository;

    @Autowired
    private ActionSubmissionRepository submissionRepository;

    @Autowired
    private EvidenceRepository evidenceRepository;

    @Autowired
    private SustainableActionRepository actionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PointService pointService;

    @Autowired
    private ObjectMapper objectMapper;

    private String readApiKeyFromEnvFile() {
        // First check system environment
        String envKey = System.getenv("AI_API_KEY");
        if (envKey != null && !envKey.isBlank()) {
            return envKey.trim();
        }

        // Check .env in current or parent directory
        Path[] possiblePaths = new Path[]{
                Path.of(".env"),
                Path.of("..", ".env"),
                Path.of("backend", ".env")
        };

        for (Path p : possiblePaths) {
            if (Files.exists(p)) {
                try {
                    List<String> lines = Files.readAllLines(p);
                    for (String line : lines) {
                        if (line.startsWith("AI_API_KEY=")) {
                            String k = line.substring("AI_API_KEY=".length()).trim();
                            if (!k.isBlank()) {
                                return k;
                            }
                        }
                    }
                } catch (IOException ignored) {}
            }
        }
        return null;
    }

    @Test
    @Transactional
    void testRealGeminiApiRequestAndVerificationPipeline() throws Exception {
        String apiKey = readApiKeyFromEnvFile();
        Assumptions.assumeTrue(apiKey != null && !apiKey.isBlank(),
                "Skipping real Gemini test: AI_API_KEY not found in environment or .env file.");

        log.info("Executing REAL Gemini API verification test using model: gemini-3.5-flash-lite");

        // 1. Initialize REAL Gemini client with live API key
        GeminiVisionApiClient realGeminiClient = new GeminiVisionApiClient(
                apiKey,
                "gemini-3.5-flash-lite",
                "https://generativelanguage.googleapis.com",
                20,
                objectMapper
        );

        // 2. Wrap in real AiEvidenceAnalyzer
        AiEvidenceAnalyzer realAnalyzer = new AiEvidenceAnalyzer(realGeminiClient, 0.70);

        // 3. Locate or create realistic test image
        Path realImagePath = Path.of("C:\\Users\\AYUSH PANDEY\\.gemini\\antigravity-ide\\brain\\53cedc4a-671f-49b1-829d-d190881b2bbc\\student_planting_tree_1790697413257.jpg");
        byte[] imageBytes;
        if (Files.exists(realImagePath)) {
            imageBytes = Files.readAllBytes(realImagePath);
        } else {
            // Fallback: 1x1 png or temp image
            imageBytes = new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46};
        }

        File tempFile = File.createTempFile("gemini_real_test_", ".jpg");
        Files.write(tempFile.toPath(), imageBytes);

        SustainableAction action = actionRepository.findAll().stream()
                .filter(a -> a.getTitle().contains("Tree"))
                .findFirst()
                .orElseGet(() -> {
                    SustainableAction sa = new SustainableAction();
                    sa.setTitle("Tree Plantation");
                    sa.setCategory("ENVIRONMENT");
                    sa.setDescription("Plant native trees on campus to increase tree canopy cover.");
                    sa.setEvidenceRequirements("Clear photo of planted sapling in soil with campus surroundings.");
                    sa.setStatus(ActionStatus.ACTIVE);
                    sa.setPointsReward(50);
                    return actionRepository.save(sa);
                });

        User user = new User();
        user.setEmail("real_gemini_student_" + UUID.randomUUID() + "@test.edu");
        user.setPasswordHash("hash");
        user.setFirstName("Real");
        user.setLastName("Student");
        user.setRole(com.carbontrack.backend.user.Role.STUDENT);
        user = userRepository.save(user);

        ActionSubmission submission = new ActionSubmission();
        submission.setUser(user);
        submission.setSustainableAction(action);
        submission.setStatus(SubmissionStatus.PENDING);
        submission.setServerTimestamp(LocalDateTime.now());
        submission.setClientTimestamp(LocalDateTime.now());
        submission = submissionRepository.save(submission);

        Evidence evidence = new Evidence();
        evidence.setSubmission(submission);
        evidence.setType(EvidenceType.PHOTO);
        evidence.setMimeType("image/jpeg");
        evidence.setStorageKey(tempFile.getAbsolutePath());
        evidence = evidenceRepository.save(evidence);

        // 5. Execute analysis with the REAL Gemini API
        log.info("Sending live HTTP request to Google Gemini API...");
        EvidenceAnalyzer.AnalysisResult analysisResult = realAnalyzer.analyze(evidence, action);

        // 6. Assertions on the real AI response
        assertNotNull(analysisResult, "Gemini analysis result must not be null");
        assertEquals("gemini", analysisResult.provider(), "Provider must be gemini");
        assertEquals("gemini-3.5-flash-lite", analysisResult.model(), "Model must be gemini-3.5-flash-lite");
        assertNotNull(analysisResult.explanation(), "Explanation must be present");
        assertNotNull(analysisResult.fraudRisk(), "Fraud risk must be evaluated");
        assertNotNull(analysisResult.detectedElements(), "Detected elements list must not be null");
        assertTrue(analysisResult.confidence() >= 0.0 && analysisResult.confidence() <= 1.0, "Confidence must be within [0, 1]");

        log.info("Real Gemini Response received successfully!");
        log.info("  - Is Valid: {}", analysisResult.isValid());
        log.info("  - Confidence: {}", analysisResult.confidence());
        log.info("  - Fraud Risk: {}", analysisResult.fraudRisk());
        log.info("  - Explanation: {}", analysisResult.explanation());
        log.info("  - Detected Elements: {}", analysisResult.detectedElements());

        // 7. Verify submission through VerificationService
        VerificationService verificationService = new VerificationService(evidenceRepository, realAnalyzer, verificationResultRepository);
        VerificationResult verificationResult = verificationService.verifySubmission(submission);

        assertNotNull(verificationResult);
        assertEquals("gemini", verificationResult.getAiProvider());
        assertEquals("gemini-3.5-flash-lite", verificationResult.getAiModel());
        assertNotNull(verificationResult.getAiFraudRisk());
        assertNotNull(verificationResult.getStatus());

        // Ensure status is either VERIFIED (if clean genuine photo) or REVIEW_REQUIRED (if flagged for authenticity)
        assertTrue(verificationResult.getStatus() == SubmissionStatus.VERIFIED ||
                        verificationResult.getStatus() == SubmissionStatus.REVIEW_REQUIRED,
                "Status must be VERIFIED or REVIEW_REQUIRED, but was: " + verificationResult.getStatus());

        // Clean up temp file
        tempFile.delete();
    }
}
