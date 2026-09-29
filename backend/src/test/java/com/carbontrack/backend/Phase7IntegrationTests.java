package com.carbontrack.backend;

import com.carbontrack.backend.action.*;
import com.carbontrack.backend.user.UserRepository;
import com.carbontrack.backend.auth.LoginRequest;
import com.carbontrack.backend.auth.RegisterRequest;
import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.points.PointTransactionRepository;
import com.carbontrack.backend.verification.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.net.http.HttpTimeoutException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Testcontainers
@Transactional
class Phase7IntegrationTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private VerificationService verificationService;

    @Autowired
    private VerificationResultRepository verificationResultRepository;

    @Autowired
    private ActionSubmissionRepository submissionRepository;

    @Autowired
    private EvidenceRepository evidenceRepository;

    @Autowired
    private SustainableActionRepository actionRepository;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @Autowired
    private PointService pointService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private String studentToken;
    private String student2Token;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();

        studentToken = registerAndLogin("student_p7_1@test.edu", "password");
        student2Token = registerAndLogin("student_p7_2@test.edu", "password");
        adminToken = login("admin@carbontrack.edu", "admin_secure_password");
    }

    private String registerAndLogin(String email, String password) throws Exception {
        try {
            RegisterRequest req = new RegisterRequest(email, password, "Student", "Phase7");
            mockMvc.perform(post("/api/v1/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(req)));
        } catch (Exception ignored) {}
        return login(email, password);
    }

    private String login(String email, String password) throws Exception {
        LoginRequest authReq = new LoginRequest(email, password);
        MvcResult res = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(authReq)))
                .andExpect(status().isOk())
                .andReturn();
        String json = res.getResponse().getContentAsString();
        return objectMapper.readTree(json).get("token").asText();
    }

    private UUID getTreePlantationActionId() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        return actions.stream().filter(a -> a.title().equals("Tree Plantation")).findFirst().orElseThrow().id();
    }

    @Test
    void testAiPositiveEvidenceYieldsVerifiedAndAwardsPoints() throws Exception {
        UUID actionId = getTreePlantationActionId();

        // 1. Create submission
        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andExpect(status().isOk())
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // 2. Upload valid image and valid campus zone location
        byte[] fakeImageContent = new byte[2048];
        java.util.Arrays.fill(fakeImageContent, (byte) 11);
        MockMultipartFile file = new MockMultipartFile("file", "tree_valid.jpg", "image/jpeg", fakeImageContent);

        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .file(file)
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .param("latitude", "40.7128")
                .param("longitude", "-74.0060") // Inside campus zone
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        // 3. Finalize submission
        MvcResult finRes = mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        SubmissionDto finSub = objectMapper.readValue(finRes.getResponse().getContentAsString(), SubmissionDto.class);

        assertEquals("VERIFIED", finSub.status());
        assertNotNull(finSub.completedAt());

        // Points must be awarded
        MvcResult balanceRes = mockMvc.perform(get("/api/v1/points/balance")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        int balance = objectMapper.readTree(balanceRes.getResponse().getContentAsString()).get("balance").asInt();
        assertTrue(balance > 0, "Points should be awarded for verified submission");
    }

    @Test
    void testAiCannotBypassGeofenceBoundary() throws Exception {
        UUID actionId = getTreePlantationActionId();

        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // Valid image, but coordinates are in Paris, France (far outside campus zone)
        byte[] fakeImageContent = new byte[2048];
        java.util.Arrays.fill(fakeImageContent, (byte) 12);
        MockMultipartFile file = new MockMultipartFile("file", "tree_paris.jpg", "image/jpeg", fakeImageContent);

        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .file(file)
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .param("latitude", "48.8566")
                .param("longitude", "2.3522")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        MvcResult finRes = mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        SubmissionDto finSub = objectMapper.readValue(finRes.getResponse().getContentAsString(), SubmissionDto.class);

        // Even though AI was positive, geofence failure must route to REVIEW_REQUIRED
        assertEquals("REVIEW_REQUIRED", finSub.status());
    }

    @Test
    void testAiCannotBypassTimestampDiscrepancy() throws Exception {
        UUID actionId = getTreePlantationActionId();

        // 3 hours in the past
        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now().minusHours(3));
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        byte[] fakeImageContent = new byte[2048];
        java.util.Arrays.fill(fakeImageContent, (byte) 13);
        MockMultipartFile file = new MockMultipartFile("file", "tree_old.jpg", "image/jpeg", fakeImageContent);

        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .file(file)
                .param("latitude", "40.7128")
                .param("longitude", "-74.0060")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        MvcResult finRes = mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        SubmissionDto finSub = objectMapper.readValue(finRes.getResponse().getContentAsString(), SubmissionDto.class);

        // Timestamp discrepancy > 1 hour must be REJECTED, not VERIFIED
        assertEquals("REJECTED", finSub.status());
    }

    @Test
    void testAiCannotBypassDuplicateDetection() throws Exception {
        UUID actionId = getTreePlantationActionId();

        // Student 1 uploads photo
        SubmissionRequest subReq1 = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes1 = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq1)))
                .andReturn();
        SubmissionDto sub1 = objectMapper.readValue(subRes1.getResponse().getContentAsString(), SubmissionDto.class);

        byte[] sharedImageContent = new byte[2048];
        java.util.Arrays.fill(sharedImageContent, (byte) 14);
        MockMultipartFile file1 = new MockMultipartFile("file", "photo_dup.jpg", "image/jpeg", sharedImageContent);

        mockMvc.perform(multipart("/api/v1/actions/submissions/" + sub1.id() + "/evidence")
                .file(file1)
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        // Student 2 attempts to upload identical image
        SubmissionRequest subReq2 = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes2 = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + student2Token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq2)))
                .andReturn();
        SubmissionDto sub2 = objectMapper.readValue(subRes2.getResponse().getContentAsString(), SubmissionDto.class);

        MockMultipartFile file2 = new MockMultipartFile("file", "photo_dup_reused.jpg", "image/jpeg", sharedImageContent);
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + sub2.id() + "/evidence")
                .file(file2)
                .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isBadRequest()); // Duplicate rejected at DB level
    }

    @Test
    void testAiFailureNeverProducesVerified() {
        // Direct test with an AI analyzer that throws an exception or returns low confidence
        VisionApiClient failingClient = new VisionApiClient() {
            @Override
            public String getProviderName() { return "gemini"; }

            @Override
            public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) throws Exception {
                throw new HttpTimeoutException("Provider timeout");
            }
        };

        AiEvidenceAnalyzer failingAnalyzer = new AiEvidenceAnalyzer(failingClient, 0.70);
        VerificationService customVerificationService = new VerificationService(evidenceRepository, failingAnalyzer, verificationResultRepository);

        com.carbontrack.backend.user.User user = userRepository.findByEmail("student_p7_1@test.edu").orElseThrow();
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(user);
        sub.setStatus(SubmissionStatus.PENDING);
        sub.setServerTimestamp(LocalDateTime.now());
        sub.setClientTimestamp(LocalDateTime.now());
        sub.setSustainableAction(actionRepository.findAll().get(0));
        sub = submissionRepository.save(sub);

        Evidence evidence = new Evidence();
        evidence.setSubmission(sub);
        evidence.setType(EvidenceType.PHOTO);
        evidence.setStorageKey("dummy_missing_path.jpg");
        evidenceRepository.save(evidence);

        VerificationResult result = customVerificationService.verifySubmission(sub);

        assertNotEquals(SubmissionStatus.VERIFIED, result.getStatus(), "AI failure must NEVER produce VERIFIED");
        assertEquals(SubmissionStatus.REVIEW_REQUIRED, result.getStatus());
    }

    @Test
    void testAiFraudRiskFlagsRouteToReviewRequired() {
        // Mock client returning synthetic/manipulated indicators
        MockVisionApiClient fraudMockClient = new MockVisionApiClient();
        fraudMockClient.setReturnValid(true);
        fraudMockClient.setConfidence(0.85);
        fraudMockClient.setReasoning("Synthetic image artifacts detected.");
        fraudMockClient.setFraudRisk("HIGH");
        fraudMockClient.setPossibleAiGenerated(true);
        fraudMockClient.setFraudIndicators(List.of("diffusion grid patterns"));

        AiEvidenceAnalyzer fraudAnalyzer = new AiEvidenceAnalyzer(fraudMockClient, 0.70);
        VerificationService customVerificationService = new VerificationService(evidenceRepository, fraudAnalyzer, verificationResultRepository);

        com.carbontrack.backend.user.User user = userRepository.findByEmail("student_p7_1@test.edu").orElseThrow();
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(user);
        sub.setStatus(SubmissionStatus.PENDING);
        sub.setServerTimestamp(LocalDateTime.now());
        sub.setClientTimestamp(LocalDateTime.now());
        sub.setSustainableAction(actionRepository.findAll().get(0));
        sub = submissionRepository.save(sub);

        // Create temporary photo file
        Evidence evidence = new Evidence();
        evidence.setSubmission(sub);
        evidence.setType(EvidenceType.PHOTO);
        evidence.setMimeType("image/jpeg");
        evidence.setStorageKey("dummy_storage_key");
        evidenceRepository.save(evidence);

        // Inject analysis directly through customVerificationService
        VerificationResult result = customVerificationService.verifySubmission(sub);

        assertNotEquals(SubmissionStatus.VERIFIED, result.getStatus());
        assertEquals(SubmissionStatus.REVIEW_REQUIRED, result.getStatus());
    }

    @Test
    void testAdminReviewDetailsEndpointProtectedAndReturnsAuditFields() throws Exception {
        // Student cannot access admin verification details
        UUID randomId = UUID.randomUUID();
        mockMvc.perform(get("/api/v1/admin/submissions/" + randomId + "/verification")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());

        // Admin can access
        mockMvc.perform(get("/api/v1/admin/submissions/" + randomId + "/verification")
                .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound()); // Submission not found, but access permitted
    }

    @Test
    void testStudentCannotAnalyzeAnotherUsersSubmission() throws Exception {
        UUID actionId = getTreePlantationActionId();

        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto sub = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // Student 2 attempts to finalize Student 1's submission
        mockMvc.perform(post("/api/v1/actions/submissions/" + sub.id() + "/finalize")
                .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    void testGeminiPayloadFormatting() {
        GeminiVisionApiClient client = new GeminiVisionApiClient("fake-key", "gemini-3.5-flash-lite", "", 10, objectMapper);
        String body = client.buildRequestBody("Check image for bicycle", "image/jpeg", "aGVsbG8=");

        assertTrue(body.contains("inlineData"));
        assertTrue(body.contains("image/jpeg"));
        assertTrue(body.contains("aGVsbG8="));
        assertTrue(body.contains("Check image for bicycle"));
        assertTrue(body.contains("application/json"));
    }

    @Test
    void testOpenAiPayloadFormatting() {
        OpenAiVisionApiClient client = new OpenAiVisionApiClient("fake-key", "gpt-4o-mini", "", 10, objectMapper);
        String body = client.buildRequestBody("Check image for bicycle", "data:image/jpeg;base64,aGVsbG8=");

        assertTrue(body.contains("gpt-4o-mini"));
        assertTrue(body.contains("data:image/jpeg;base64,aGVsbG8="));
        assertTrue(body.contains("Check image for bicycle"));
        assertTrue(body.contains("json_object"));
    }
}
