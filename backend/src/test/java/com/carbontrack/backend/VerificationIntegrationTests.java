package com.carbontrack.backend;

import com.carbontrack.backend.action.*;
import com.carbontrack.backend.auth.LoginRequest;
import com.carbontrack.backend.auth.RegisterRequest;
import com.carbontrack.backend.verification.EvidenceRepository;
import com.carbontrack.backend.verification.VerificationResultRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;

@SpringBootTest
@Testcontainers
@Transactional
class VerificationIntegrationTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private String studentToken;
    private String student2Token;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();

        studentToken = registerAndLogin("student1@test.edu", "password");
        student2Token = registerAndLogin("student2@test.edu", "password");
        adminToken = login("admin@carbontrack.edu", "admin_secure_password"); // Seeded admin
    }

    private String registerAndLogin(String email, String password) throws Exception {
        try {
            RegisterRequest req = new RegisterRequest(email, password, "First", "Last");
            mockMvc.perform(post("/api/v1/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(req)));
        } catch (Exception e) {}
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

    @Test
    void testStudentCanViewActions() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        List<ActionDto> actions = objectMapper.readValue(res.getResponse().getContentAsString(), new TypeReference<>() {});
        assertFalse(actions.isEmpty());
    }

    @Test
    void testVerificationFlow() throws Exception {
        // 1. Get Actions
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken))
                .andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.stream().filter(a -> a.title().equals("Tree Plantation")).findFirst().get().id();

        // 2. Create Submission
        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andExpect(status().isOk())
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // 3. Add Valid Evidence (Image & Location)
        byte[] fakeImageContent = new byte[1024];
        java.util.Arrays.fill(fakeImageContent, (byte) 1);
        MockMultipartFile file = new MockMultipartFile("file", "test.jpg", "image/jpeg", fakeImageContent);
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .file(file)
                .param("latitude", "40.7128")
                .param("longitude", "-74.0060") // Exact same coordinates as CampusZone
                .header("Authorization", "Bearer " + studentToken))
                .andDo(print())
                .andExpect(status().isOk());

        MvcResult finRes = mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andReturn();
        SubmissionDto finSub = objectMapper.readValue(finRes.getResponse().getContentAsString(), SubmissionDto.class);
        assertEquals("VERIFIED", finSub.status()); // Mock analyzer passes, Location matches
    }

    @Test
    void testDuplicateEvidenceDetection() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken)).andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.get(0).id();

        // 1. First Submission (Student 1)
        SubmissionRequest subReq1 = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes1 = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq1)))
                .andReturn();
        SubmissionDto sub1 = objectMapper.readValue(subRes1.getResponse().getContentAsString(), SubmissionDto.class);

        byte[] fakeImageContent = new byte[1024];
        java.util.Arrays.fill(fakeImageContent, (byte) 3);
        MockMultipartFile file = new MockMultipartFile("file", "test.jpg", "image/jpeg", fakeImageContent);
        
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + sub1.id() + "/evidence")
                .file(file).header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        // 2. Second Submission (Student 2)
        SubmissionRequest subReq2 = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes2 = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + student2Token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq2)))
                .andReturn();
        SubmissionDto sub2 = objectMapper.readValue(subRes2.getResponse().getContentAsString(), SubmissionDto.class);

        // Uploading exact same file -> throws DataIntegrityViolationException mapped to 400
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + sub2.id() + "/evidence")
                .file(file).header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testAdminReviewAccess() throws Exception {
        mockMvc.perform(get("/api/v1/admin/submissions/review")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden()); // Student can't access admin

        mockMvc.perform(get("/api/v1/admin/submissions/review")
                .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    void testIdorOnFinalizeSubmission() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken)).andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.get(0).id();

        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // Student 2 tries to finalize Student 1's submission
        mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    void testStateTransitionOnFinalize() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken)).andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.get(0).id();

        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // First finalize
        mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        // Second finalize should fail (state is not PENDING)
        mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testGeofenceBoundary() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken)).andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.stream().filter(a -> a.title().equals("Tree Plantation")).findFirst().get().id();

        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        // Upload with coordinates far from Campus Zone
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .param("latitude", "48.8566") // Paris, France
                .param("longitude", "2.3522")
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk());

        MvcResult finRes = mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andReturn();
        SubmissionDto finSub = objectMapper.readValue(finRes.getResponse().getContentAsString(), SubmissionDto.class);
        assertEquals("REVIEW_REQUIRED", finSub.status()); // Rejected due to location, routed to manual review
    }

    @Test
    void testTimestampValidation() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken)).andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.get(0).id();

        // 2 hours ago
        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now().minusHours(2));
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        MvcResult finRes = mockMvc.perform(post("/api/v1/actions/submissions/" + submission.id() + "/finalize")
                .header("Authorization", "Bearer " + studentToken))
                .andReturn();
        SubmissionDto finSub = objectMapper.readValue(finRes.getResponse().getContentAsString(), SubmissionDto.class);
        assertEquals("REJECTED", finSub.status());
    }

    @Test
    void testPathTraversalAttempt() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                .header("Authorization", "Bearer " + studentToken)).andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        UUID actionId = actions.get(0).id();

        SubmissionRequest subReq = new SubmissionRequest(actionId, LocalDateTime.now());
        MvcResult subRes = mockMvc.perform(post("/api/v1/actions/submissions")
                .header("Authorization", "Bearer " + studentToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(subReq)))
                .andReturn();
        SubmissionDto submission = objectMapper.readValue(subRes.getResponse().getContentAsString(), SubmissionDto.class);

        byte[] fakeImageContent = new byte[1024];
        java.util.Arrays.fill(fakeImageContent, (byte) 2);
        // Attempt Path Traversal in filename
        MockMultipartFile file = new MockMultipartFile("file", "../../../etc/passwd", "image/jpeg", fakeImageContent);
        
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submission.id() + "/evidence")
                .file(file)
                .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk()); // Handled gracefully, filename stripped of path and given UUID.
    }
}
