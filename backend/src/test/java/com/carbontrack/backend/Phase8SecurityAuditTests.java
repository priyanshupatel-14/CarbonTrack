package com.carbontrack.backend;

import com.carbontrack.backend.action.*;
import com.carbontrack.backend.auth.LoginRequest;
import com.carbontrack.backend.auth.RegisterRequest;
import com.carbontrack.backend.carbon.ActivityType;
import com.carbontrack.backend.carbon.CarbonActivityRequest;
import com.carbontrack.backend.carbon.Category;
import com.carbontrack.backend.challenge.Challenge;
import com.carbontrack.backend.challenge.ChallengeRepository;
import com.carbontrack.backend.challenge.ChallengeStatus;
import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.points.PointTransactionRepository;
import com.carbontrack.backend.rewards.*;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import com.carbontrack.backend.verification.LocalEvidenceStorageService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Testcontainers
@Transactional
public class Phase8SecurityAuditTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RewardRepository rewardRepository;

    @Autowired
    private CouponRepository couponRepository;

    @Autowired
    private ActionSubmissionRepository submissionRepository;

    @Autowired
    private ChallengeRepository challengeRepository;

    @Autowired
    private SustainableActionRepository actionRepository;

    @Autowired
    private PointService pointService;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private LocalEvidenceStorageService localEvidenceStorageService;

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private String student1Token;
    private String student2Token;
    private String merchant1Token;
    private String merchant2Token;
    private String adminToken;

    private User student1;
    private User student2;
    private User merchant1;
    private User merchant2;
    private User admin;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();

        student1 = getOrCreateUser("sec_student1@test.edu", Role.STUDENT, "StudentOne", "Sec");
        student2 = getOrCreateUser("sec_student2@test.edu", Role.STUDENT, "StudentTwo", "Sec");
        merchant1 = getOrCreateUser("sec_merchant1@test.edu", Role.MERCHANT, "MerchantOne", "Sec");
        merchant2 = getOrCreateUser("sec_merchant2@test.edu", Role.MERCHANT, "MerchantTwo", "Sec");
        admin = getOrCreateUser("admin@carbontrack.edu", Role.ADMIN, "Admin", "User");

        student1Token = login("sec_student1@test.edu", "secure_test_password");
        student2Token = login("sec_student2@test.edu", "secure_test_password");
        merchant1Token = login("sec_merchant1@test.edu", "secure_test_password");
        merchant2Token = login("sec_merchant2@test.edu", "secure_test_password");
        adminToken = login("admin@carbontrack.edu", "admin_secure_password");
    }

    private User getOrCreateUser(String email, Role role, String first, String last) {
        return userRepository.findByEmail(email).orElseGet(() -> {
            User u = new User();
            u.setEmail(email);
            u.setPasswordHash(passwordEncoder.encode(role == Role.ADMIN ? "admin_secure_password" : "secure_test_password"));
            u.setFirstName(first);
            u.setLastName(last);
            u.setRole(role);
            return userRepository.save(u);
        });
    }

    private String login(String email, String password) throws Exception {
        LoginRequest req = new LoginRequest(email, password);
        MvcResult res = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(res.getResponse().getContentAsString()).get("token").asText();
    }

    private UUID getTreePlantationActionId() throws Exception {
        MvcResult actionsRes = mockMvc.perform(get("/api/v1/actions")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isOk())
                .andReturn();
        List<ActionDto> actions = objectMapper.readValue(actionsRes.getResponse().getContentAsString(), new TypeReference<>() {});
        return actions.stream().filter(a -> a.title().equals("Tree Plantation")).findFirst().orElseThrow().id();
    }

    // ==========================================
    // 1. AUTHENTICATION & JWT INTEGRITY TESTS
    // ==========================================

    @Test
    @DisplayName("Auth: Invalid credentials returns 401 Unauthorized")
    void testInvalidCredentialsReturns401() throws Exception {
        LoginRequest req = new LoginRequest("sec_student1@test.edu", "wrong_password");
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Auth: Tampered or invalid JWT token is rejected with 403 Forbidden")
    void testInvalidJwtRejected() throws Exception {
        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer invalid.tampered.jwt.signature"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Auth: Missing Authorization header on protected endpoint is rejected with 403 Forbidden")
    void testMissingAuthHeaderRejected() throws Exception {
        mockMvc.perform(get("/api/v1/users/me"))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // 2. AUTHORIZATION & RBAC TESTS
    // ==========================================

    @Test
    @DisplayName("RBAC: Student cannot access Admin endpoints")
    void testStudentCannotAccessAdminEndpoints() throws Exception {
        // GET /api/v1/admin/users
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isForbidden());

        // GET /api/v1/admin/submissions/review
        mockMvc.perform(get("/api/v1/admin/submissions/review")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isForbidden());

        // POST /api/v1/admin/rewards
        CreateRewardRequest req = new CreateRewardRequest(merchant1.getId(), "Hacked", "Desc", 10, 10, null);
        mockMvc.perform(post("/api/v1/admin/rewards")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());

        // GET /api/v1/admin/challenges
        mockMvc.perform(get("/api/v1/admin/challenges")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("RBAC: Student cannot access Merchant endpoints")
    void testStudentCannotAccessMerchantEndpoints() throws Exception {
        mockMvc.perform(get("/api/v1/merchant/profile")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isForbidden());

        CouponActionRequest couponReq = new CouponActionRequest("ANY_CODE");
        mockMvc.perform(post("/api/v1/merchant/coupons/validate")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(couponReq)))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/v1/merchant/coupons/consume")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(couponReq)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("RBAC: Merchant cannot access Admin endpoints")
    void testMerchantCannotAccessAdminEndpoints() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + merchant1Token))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/admin/challenges")
                        .header("Authorization", "Bearer " + merchant1Token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("RBAC: Merchant cannot join Student challenges")
    void testMerchantCannotJoinChallenges() throws Exception {
        Challenge challenge = challengeRepository.findAll().stream().findFirst().orElse(null);
        if (challenge != null) {
            mockMvc.perform(post("/api/v1/challenges/" + challenge.getId() + "/join")
                            .header("Authorization", "Bearer " + merchant1Token))
                    .andExpect(status().isForbidden());
        }
    }

    // ==========================================
    // 3. IDOR & RESOURCE ISOLATION TESTS
    // ==========================================

    @Test
    @DisplayName("IDOR: Student 2 cannot access or inspect Student 1's submission")
    void testStudentCannotAccessOtherStudentsSubmission() throws Exception {
        UUID actionId = getTreePlantationActionId();

        // Student 1 creates submission
        MvcResult createRes = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        UUID submissionId = UUID.fromString(objectMapper.readTree(createRes.getResponse().getContentAsString()).get("id").asText());

        // Student 2 tries to GET Student 1's submission -> 403 Forbidden
        mockMvc.perform(get("/api/v1/actions/submissions/" + submissionId)
                        .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("IDOR: Student 2 cannot attach evidence to Student 1's submission")
    void testStudentCannotAddEvidenceToOtherStudentsSubmission() throws Exception {
        UUID actionId = getTreePlantationActionId();

        MvcResult createRes = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        UUID submissionId = UUID.fromString(objectMapper.readTree(createRes.getResponse().getContentAsString()).get("id").asText());

        MockMultipartFile file = new MockMultipartFile("file", "test.jpg", "image/jpeg", "dummy".getBytes());
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + submissionId + "/evidence")
                        .file(file)
                        .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("IDOR: Student 2 cannot finalize Student 1's submission")
    void testStudentCannotFinalizeOtherStudentsSubmission() throws Exception {
        UUID actionId = getTreePlantationActionId();

        MvcResult createRes = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        UUID submissionId = UUID.fromString(objectMapper.readTree(createRes.getResponse().getContentAsString()).get("id").asText());

        mockMvc.perform(post("/api/v1/actions/submissions/" + submissionId + "/finalize")
                        .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // 4. MERCHANT COUPON ISOLATION TESTS
    // ==========================================

    @Test
    @DisplayName("Merchant Isolation: Merchant 2 cannot validate or consume Merchant 1's coupon")
    void testMerchantCouponIsolation() throws Exception {
        // 1. Admin creates reward for Merchant 1
        Reward reward1 = new Reward();
        reward1.setName("M1 Coffee Coupon");
        reward1.setDescription("Free Coffee from Merchant 1");
        reward1.setPointsRequired(10);
        reward1.setInventory(5);
        reward1.setStatus(RewardStatus.ACTIVE);
        reward1.setMerchant(merchant1);
        reward1 = rewardRepository.save(reward1);

        // 2. Give student 100 points
        com.carbontrack.backend.points.PointTransaction pt = new com.carbontrack.backend.points.PointTransaction();
        pt.setUser(student1);
        pt.setTransactionType(com.carbontrack.backend.points.TransactionType.EARN);
        pt.setPoints(100);
        pt.setReferenceType("TEST_SEED");
        pt.setReferenceId(UUID.randomUUID().toString());
        pt.setDescription("Test initial balance");
        pointTransactionRepository.saveAndFlush(pt);

        // 3. Student redeems reward1
        MvcResult redeemRes = mockMvc.perform(post("/api/v1/rewards/" + reward1.getId() + "/redeem")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isOk())
                .andReturn();
        String couponCode = objectMapper.readTree(redeemRes.getResponse().getContentAsString()).get("code").asText();
        assertNotNull(couponCode);

        // 4. Merchant 2 attempts to validate Merchant 1's coupon -> 403 Forbidden
        CouponActionRequest actionReq = new CouponActionRequest(couponCode);
        mockMvc.perform(post("/api/v1/merchant/coupons/validate")
                        .header("Authorization", "Bearer " + merchant2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(actionReq)))
                .andExpect(status().isForbidden());

        // 5. Merchant 2 attempts to consume Merchant 1's coupon -> 403 Forbidden
        mockMvc.perform(post("/api/v1/merchant/coupons/consume")
                        .header("Authorization", "Bearer " + merchant2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(actionReq)))
                .andExpect(status().isForbidden());

        // 6. Merchant 1 validates their own coupon -> 200 OK
        mockMvc.perform(post("/api/v1/merchant/coupons/validate")
                        .header("Authorization", "Bearer " + merchant1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(actionReq)))
                .andExpect(status().isOk());

        // 7. Merchant 1 consumes their own coupon -> 200 OK
        mockMvc.perform(post("/api/v1/merchant/coupons/consume")
                        .header("Authorization", "Bearer " + merchant1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(actionReq)))
                .andExpect(status().isOk());

        // 8. Re-consuming already redeemed coupon returns 400 Bad Request
        mockMvc.perform(post("/api/v1/merchant/coupons/consume")
                        .header("Authorization", "Bearer " + merchant1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(actionReq)))
                .andExpect(status().isBadRequest());
    }

    // ==========================================
    // 5. EVIDENCE UPLOAD SECURITY & INTEGRITY
    // ==========================================

    @Test
    @DisplayName("Evidence: Rejects non-image MIME type")
    void testRejectsNonImageUpload() throws Exception {
        UUID actionId = getTreePlantationActionId();
        MvcResult createRes = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        UUID subId = UUID.fromString(objectMapper.readTree(createRes.getResponse().getContentAsString()).get("id").asText());

        MockMultipartFile badFile = new MockMultipartFile("file", "script.sh", "application/x-sh", "echo evil".getBytes());
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId + "/evidence")
                        .file(badFile)
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Evidence: Storage contains path traversal attempts and keeps files inside directory")
    void testEvidenceStoragePathTraversalContainment() throws Exception {
        Path storageDir = localEvidenceStorageService.getStorageLocation();
        assertNotNull(storageDir);
        assertTrue(Files.exists(storageDir));

        // Attempting to delete file outside storage dir throws SecurityException
        assertThrows(SecurityException.class, () -> {
            localEvidenceStorageService.deleteEvidence("../../etc/passwd");
        });

        // Uploading with traversal filename stores file safely inside directory with UUID name
        MockMultipartFile traversalFile = new MockMultipartFile(
                "file",
                "../../../../evil.jpg",
                "image/jpeg",
                "legitimate_bytes".getBytes()
        );
        String storedPath = localEvidenceStorageService.storeEvidence(traversalFile);
        Path resolved = Path.of(storedPath).normalize();
        assertTrue(resolved.startsWith(storageDir.normalize()), "Stored file must be contained inside the configured directory");
        assertFalse(resolved.toString().contains("evil.jpg"), "Original path traversal filename must be sanitized to random UUID");
        Files.deleteIfExists(resolved);
    }

    @Test
    @DisplayName("Evidence: Duplicate evidence SHA-256 is rejected")
    void testDuplicateEvidenceRejected() throws Exception {
        UUID actionId = getTreePlantationActionId();

        // Submission 1
        MvcResult res1 = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk()).andReturn();
        UUID subId1 = UUID.fromString(objectMapper.readTree(res1.getResponse().getContentAsString()).get("id").asText());

        byte[] identicalImage = "unique_image_content_12345".getBytes();
        MockMultipartFile file1 = new MockMultipartFile("file", "photo1.jpg", "image/jpeg", identicalImage);
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId1 + "/evidence")
                        .file(file1)
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isOk());

        // Submission 2
        MvcResult res2 = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk()).andReturn();
        UUID subId2 = UUID.fromString(objectMapper.readTree(res2.getResponse().getContentAsString()).get("id").asText());

        MockMultipartFile file2 = new MockMultipartFile("file", "photo2_different_name.jpg", "image/jpeg", identicalImage);
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId2 + "/evidence")
                        .file(file2)
                        .header("Authorization", "Bearer " + student2Token))
                .andExpect(status().isBadRequest());
    }

    // ==========================================
    // 6. GEOFENCE COORDINATE VALIDATION TESTS
    // ==========================================

    @Test
    @DisplayName("Geofence: Invalid coordinates are rejected with 400 Bad Request")
    void testInvalidCoordinatesRejected() throws Exception {
        UUID actionId = getTreePlantationActionId();
        MvcResult res = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk()).andReturn();
        UUID subId = UUID.fromString(objectMapper.readTree(res.getResponse().getContentAsString()).get("id").asText());

        // Latitude > 90
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId + "/evidence")
                        .param("latitude", "95.0")
                        .param("longitude", "77.0")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());

        // Longitude > 180
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId + "/evidence")
                        .param("latitude", "40.0")
                        .param("longitude", "190.0")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());

        // Longitude missing
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId + "/evidence")
                        .param("latitude", "40.0")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());
    }

    // ==========================================
    // 7. STATE MACHINE & FINALIZATION IMMUTABILITY
    // ==========================================

    @Test
    @DisplayName("State Machine: Cannot add evidence or re-finalize already completed submission")
    void testCannotAlterFinalizedSubmission() throws Exception {
        UUID actionId = getTreePlantationActionId();
        MvcResult res = mockMvc.perform(post("/api/v1/actions/submissions")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sustainableActionId\":\"" + actionId + "\"}"))
                .andExpect(status().isOk()).andReturn();
        UUID subId = UUID.fromString(objectMapper.readTree(res.getResponse().getContentAsString()).get("id").asText());

        MockMultipartFile file = new MockMultipartFile("file", "valid.jpg", "image/jpeg", "image_for_state_test".getBytes());
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId + "/evidence")
                        .file(file)
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isOk());

        // Finalize -> becomes VERIFIED or REVIEW_REQUIRED
        mockMvc.perform(post("/api/v1/actions/submissions/" + subId + "/finalize")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isOk());

        // Attempt to re-finalize
        mockMvc.perform(post("/api/v1/actions/submissions/" + subId + "/finalize")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());

        // Attempt to add more evidence to finalized submission
        MockMultipartFile extraFile = new MockMultipartFile("file", "extra.jpg", "image/jpeg", "extra_bytes".getBytes());
        mockMvc.perform(multipart("/api/v1/actions/submissions/" + subId + "/evidence")
                        .file(extraFile)
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());
    }

    // ==========================================
    // 8. POINTS LEDGER IDEMPOTENCY
    // ==========================================

    @Test
    @DisplayName("Points: One logical event cannot award points twice")
    void testPointAwardIdempotency() throws Exception {
        UUID actionId = getTreePlantationActionId();
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(actionRepository.findById(actionId).orElseThrow());
        sub.setStatus(SubmissionStatus.VERIFIED);
        sub = submissionRepository.saveAndFlush(sub);

        int balanceBefore = pointService.getBalance(student1);

        // Award points first time
        pointService.awardPointsForSubmission(sub);
        int balanceAfterFirst = pointService.getBalance(student1);
        assertTrue(balanceAfterFirst > balanceBefore);

        // Award points second time for exact same submission
        pointService.awardPointsForSubmission(sub);
        int balanceAfterSecond = pointService.getBalance(student1);

        assertEquals(balanceAfterFirst, balanceAfterSecond, "Duplicate point award must be safely prevented by ledger unique constraint");
    }

    // ==========================================
    // 9. REWARDS & INVENTORY PROTECTION
    // ==========================================

    @Test
    @DisplayName("Rewards: Cannot redeem with insufficient points or out-of-stock inventory")
    void testRewardRedemptionGuards() throws Exception {
        Reward reward = new Reward();
        reward.setName("Expensive Laptop Sleeve");
        reward.setDescription("Requires 5000 points");
        reward.setPointsRequired(5000);
        reward.setInventory(1);
        reward.setStatus(RewardStatus.ACTIVE);
        reward.setMerchant(merchant1);
        reward = rewardRepository.save(reward);

        // Student has < 5000 points
        mockMvc.perform(post("/api/v1/rewards/" + reward.getId() + "/redeem")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());

        // Out of stock reward
        Reward outOfStock = new Reward();
        outOfStock.setName("Sold Out Item");
        outOfStock.setPointsRequired(5);
        outOfStock.setInventory(0);
        outOfStock.setStatus(RewardStatus.OUT_OF_STOCK);
        outOfStock.setMerchant(merchant1);
        outOfStock = rewardRepository.save(outOfStock);

        mockMvc.perform(post("/api/v1/rewards/" + outOfStock.getId() + "/redeem")
                        .header("Authorization", "Bearer " + student1Token))
                .andExpect(status().isBadRequest());
    }

    // ==========================================
    // 10. CHALLENGE INTEGRITY
    // ==========================================

    @Test
    @DisplayName("Challenges: Student cannot join the same challenge twice")
    void testDuplicateChallengeJoinRejection() throws Exception {
        Challenge challenge = challengeRepository.findAll().stream()
                .filter(c -> c.getStatus() == ChallengeStatus.ACTIVE)
                .findFirst().orElse(null);

        if (challenge != null) {
            // First join -> 200 OK
            mockMvc.perform(post("/api/v1/challenges/" + challenge.getId() + "/join")
                            .header("Authorization", "Bearer " + student1Token))
                    .andExpect(status().isOk());

            // Second join -> 400 Bad Request
            mockMvc.perform(post("/api/v1/challenges/" + challenge.getId() + "/join")
                            .header("Authorization", "Bearer " + student1Token))
                    .andExpect(status().isBadRequest());
        }
    }

    // ==========================================
    // 11. CARBON ACTIVITY INPUT VALIDATION
    // ==========================================

    @Test
    @DisplayName("Carbon: Future activity date is rejected with 400 Bad Request")
    void testCarbonActivityFutureDateRejected() throws Exception {
        CarbonActivityRequest futureReq = new CarbonActivityRequest(
                Category.TRANSPORTATION,
                ActivityType.PUBLIC_BUS,
                BigDecimal.valueOf(10),
                "km",
                LocalDate.now().plusDays(5),
                "Future commute"
        );

        mockMvc.perform(post("/api/v1/carbon/activities")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(futureReq)))
                .andExpect(status().isBadRequest());
    }
}
