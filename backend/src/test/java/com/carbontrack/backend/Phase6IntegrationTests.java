package com.carbontrack.backend;

import com.carbontrack.backend.action.*;
import com.carbontrack.backend.challenge.*;
import com.carbontrack.backend.points.*;
import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import com.carbontrack.backend.verification.AdminReviewService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class Phase6IntegrationTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SustainableActionRepository actionRepository;

    @Autowired
    private ActionSubmissionRepository submissionRepository;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @Autowired
    private ChallengeRepository challengeRepository;

    @Autowired
    private ChallengeParticipationRepository participationRepository;

    @Autowired
    private ChallengeProgressEventRepository progressEventRepository;

    @Autowired
    private ChallengeService challengeService;

    @Autowired
    private PointService pointService;

    @Autowired
    private AdminReviewService adminReviewService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private User student1;
    private User student2;
    private User admin;
    private User merchant;

    private SustainableAction cyclingAction;
    private SustainableAction recyclingAction;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

        progressEventRepository.deleteAll();
        participationRepository.deleteAll();
        challengeRepository.deleteAll();
        pointTransactionRepository.deleteAll();
        jdbcTemplate.execute("DELETE FROM verification_results");
        jdbcTemplate.execute("DELETE FROM evidence");
        submissionRepository.deleteAll();
        actionRepository.deleteAll();
        jdbcTemplate.execute("DELETE FROM coupons");
        jdbcTemplate.execute("DELETE FROM reward_redemptions");
        jdbcTemplate.execute("DELETE FROM rewards");
        userRepository.deleteAll();

        student1 = createUser("student1@test.com", "Alice", "Student", Role.STUDENT);
        student2 = createUser("student2@test.com", "Bob", "Learner", Role.STUDENT);
        admin = createUser("admin@test.com", "Campus", "Admin", Role.ADMIN);
        merchant = createUser("merchant@test.com", "Campus", "Cafe", Role.MERCHANT);

        cyclingAction = new SustainableAction();
        cyclingAction.setTitle("Cycling to College");
        cyclingAction.setDescription("Ride bike");
        cyclingAction.setCategory("TRANSPORTATION");
        cyclingAction.setStatus(ActionStatus.ACTIVE);
        cyclingAction.setPointsReward(20);
        cyclingAction.setEstimatedImpact(new BigDecimal("0.5"));
        cyclingAction = actionRepository.save(cyclingAction);

        recyclingAction = new SustainableAction();
        recyclingAction.setTitle("Recycling");
        recyclingAction.setDescription("Recycle plastic or paper");
        recyclingAction.setCategory("WASTE");
        recyclingAction.setStatus(ActionStatus.ACTIVE);
        recyclingAction.setPointsReward(10);
        recyclingAction.setEstimatedImpact(new BigDecimal("0.2"));
        recyclingAction = actionRepository.save(recyclingAction);
    }

    private User createUser(String email, String firstName, String lastName, Role role) {
        User u = new User();
        u.setEmail(email);
        u.setPasswordHash("hashed_secret");
        u.setFirstName(firstName);
        u.setLastName(lastName);
        u.setRole(role);
        return userRepository.save(u);
    }

    private Challenge createChallenge(String title, SustainableAction action, int targetCount, int bonusPoints, ChallengeStatus status, LocalDateTime start, LocalDateTime end, Integer maxParticipants) {
        Challenge c = new Challenge();
        c.setTitle(title);
        c.setDescription("Description for " + title);
        c.setTargetAction(action);
        c.setTargetCount(targetCount);
        c.setBonusPoints(bonusPoints);
        c.setStatus(status);
        c.setStartDate(start);
        c.setEndDate(end);
        c.setMaxParticipants(maxParticipants);
        return challengeRepository.save(c);
    }

    // ==========================================
    // CHALLENGE LIFECYCLE TESTS (1 - 8)
    // ==========================================

    @Test
    void test1_adminCreatesChallenge() throws Exception {
        CreateChallengeRequest request = new CreateChallengeRequest(
                "Cycle 5 Times",
                "Ride bike 5 times this month",
                LocalDateTime.now().minusDays(1),
                LocalDateTime.now().plusDays(20),
                ChallengeStatus.ACTIVE,
                cyclingAction.getId(),
                5,
                50,
                50
        );

        mockMvc.perform(post("/api/v1/admin/challenges")
                        .with(user(new AuthenticatedUserPrincipal(admin)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.title").value("Cycle 5 Times"))
                .andExpect(jsonPath("$.targetCount").value(5))
                .andExpect(jsonPath("$.bonusPoints").value(50))
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        assertThat(challengeRepository.count()).isEqualTo(1);
    }

    @Test
    void test2_studentSeesActiveChallenge() throws Exception {
        createChallenge("Active Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);
        createChallenge("Draft Challenge", cyclingAction, 3, 30, ChallengeStatus.DRAFT,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        mockMvc.perform(get("/api/v1/challenges")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].title").value("Active Challenge"))
                .andExpect(jsonPath("$[0].joined").value(false));
    }

    @Test
    void test3_studentJoinsChallenge() throws Exception {
        Challenge c = createChallenge("Joinable Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        mockMvc.perform(post("/api/v1/challenges/" + c.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.challengeId").value(c.getId().toString()))
                .andExpect(jsonPath("$.status").value("JOINED"))
                .andExpect(jsonPath("$.progressCount").value(0));

        assertThat(participationRepository.count()).isEqualTo(1);
    }

    @Test
    void test4_duplicateJoinRejected() throws Exception {
        Challenge c = createChallenge("Joinable Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        // First join succeeds
        mockMvc.perform(post("/api/v1/challenges/" + c.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk());

        // Duplicate join fails
        mockMvc.perform(post("/api/v1/challenges/" + c.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("already joined")));
    }

    @Test
    void test5_inactiveChallengeCannotBeJoined() throws Exception {
        Challenge draft = createChallenge("Draft Challenge", cyclingAction, 3, 30, ChallengeStatus.DRAFT,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        mockMvc.perform(post("/api/v1/challenges/" + draft.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("not active")));
    }

    @Test
    void test6_expiredChallengeCannotBeJoined() throws Exception {
        Challenge expired = createChallenge("Expired Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(10), LocalDateTime.now().minusDays(1), null);

        mockMvc.perform(post("/api/v1/challenges/" + expired.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void test7_studentCannotModifyChallenge() throws Exception {
        Challenge c = createChallenge("Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        CreateChallengeRequest updateReq = new CreateChallengeRequest(
                "Tampered Title", "Hacked", LocalDateTime.now(), LocalDateTime.now().plusDays(5),
                ChallengeStatus.ACTIVE, cyclingAction.getId(), 1, 9999, null
        );

        mockMvc.perform(put("/api/v1/admin/challenges/" + c.getId())
                        .with(user(new AuthenticatedUserPrincipal(student1)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isForbidden());
    }

    @Test
    void test8_merchantCannotManageChallenges() throws Exception {
        CreateChallengeRequest request = new CreateChallengeRequest(
                "Merchant Challenge", "Cafe promo", LocalDateTime.now(), LocalDateTime.now().plusDays(5),
                ChallengeStatus.ACTIVE, cyclingAction.getId(), 2, 20, null
        );

        mockMvc.perform(post("/api/v1/admin/challenges")
                        .with(user(new AuthenticatedUserPrincipal(merchant)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // PROGRESS TESTS (9 - 14)
    // ==========================================

    @Test
    void test9_verifiedQualifyingActionIncrementsProgress() throws Exception {
        Challenge c = createChallenge("Cycle Challenge", cyclingAction, 3, 50, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        // Create submission and verify it via admin review service
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(cyclingAction);
        sub.setStatus(SubmissionStatus.REVIEW_REQUIRED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);

        adminReviewService.reviewSubmission(sub.getId(), true, "Valid cycling");

        ChallengeParticipation p = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p.getProgressCount()).isEqualTo(1);
        assertThat(p.getStatus()).isEqualTo(ParticipationStatus.JOINED);
    }

    @Test
    void test10_rejectedOrPendingActionDoesNotIncrementProgress() throws Exception {
        Challenge c = createChallenge("Cycle Challenge", cyclingAction, 3, 50, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        // Rejected submission
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(cyclingAction);
        sub.setStatus(SubmissionStatus.REVIEW_REQUIRED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);

        adminReviewService.reviewSubmission(sub.getId(), false, "Invalid evidence");

        ChallengeParticipation p = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p.getProgressCount()).isEqualTo(0);
    }

    @Test
    void test11_sameSubmissionCannotIncrementTwice() throws Exception {
        Challenge c = createChallenge("Cycle Challenge", cyclingAction, 3, 50, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(cyclingAction);
        sub.setStatus(SubmissionStatus.VERIFIED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);

        // Process once
        challengeService.processVerifiedSubmission(sub);
        // Process again with same submission
        challengeService.processVerifiedSubmission(sub);

        ChallengeParticipation p = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p.getProgressCount()).isEqualTo(1);
    }

    @Test
    void test12_unrelatedActionDoesNotIncrement() throws Exception {
        Challenge c = createChallenge("Cycle Challenge", cyclingAction, 3, 50, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        // Submission for RECYCLING, not CYCLING
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(recyclingAction);
        sub.setStatus(SubmissionStatus.VERIFIED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);

        challengeService.processVerifiedSubmission(sub);

        ChallengeParticipation p = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p.getProgressCount()).isEqualTo(0);
    }

    @Test
    void test13_and_14_targetCompletionAndTimestampSetOnce() throws Exception {
        Challenge c = createChallenge("Cycle Challenge", cyclingAction, 2, 50, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        // Action 1
        ActionSubmission sub1 = new ActionSubmission();
        sub1.setUser(student1);
        sub1.setSustainableAction(cyclingAction);
        sub1.setStatus(SubmissionStatus.VERIFIED);
        sub1.setSubmittedAt(LocalDateTime.now());
        sub1 = submissionRepository.save(sub1);
        challengeService.processVerifiedSubmission(sub1);

        ChallengeParticipation p1 = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p1.getStatus()).isEqualTo(ParticipationStatus.JOINED);
        assertThat(p1.getCompletedAt()).isNull();

        // Action 2 (Completing action)
        ActionSubmission sub2 = new ActionSubmission();
        sub2.setUser(student1);
        sub2.setSustainableAction(cyclingAction);
        sub2.setStatus(SubmissionStatus.VERIFIED);
        sub2.setSubmittedAt(LocalDateTime.now());
        sub2 = submissionRepository.save(sub2);
        challengeService.processVerifiedSubmission(sub2);

        ChallengeParticipation p2 = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p2.getStatus()).isEqualTo(ParticipationStatus.COMPLETED);
        assertThat(p2.getCompletedAt()).isNotNull();
        LocalDateTime originalCompletedAt = p2.getCompletedAt();

        // Extra action after completion
        ActionSubmission sub3 = new ActionSubmission();
        sub3.setUser(student1);
        sub3.setSustainableAction(cyclingAction);
        sub3.setStatus(SubmissionStatus.VERIFIED);
        sub3.setSubmittedAt(LocalDateTime.now());
        sub3 = submissionRepository.save(sub3);
        challengeService.processVerifiedSubmission(sub3);

        ChallengeParticipation p3 = participationRepository.findByChallengeAndUser(c, student1).orElseThrow();
        assertThat(p3.getCompletedAt()).isEqualTo(originalCompletedAt);
    }

    // ==========================================
    // BONUS POINTS TESTS (15 - 18)
    // ==========================================

    @Test
    void test15_and_16_completionAwardsBonusExactlyOnce() throws Exception {
        Challenge c = createChallenge("Bonus Challenge", cyclingAction, 1, 100, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(cyclingAction);
        sub.setStatus(SubmissionStatus.REVIEW_REQUIRED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);

        // Approve submission
        adminReviewService.reviewSubmission(sub.getId(), true, "Approved");

        // Action points (20) + Bonus points (100) = 120
        int balance = pointService.getBalance(student1);
        assertThat(balance).isEqualTo(120);

        // Verify bonus transaction exists in ledger
        var txs = pointTransactionRepository.findByUserOrderByCreatedAtDesc(student1);
        var bonusTx = txs.stream().filter(t -> "CHALLENGE_COMPLETION".equals(t.getReferenceType())).toList();
        assertThat(bonusTx).hasSize(1);
        assertThat(bonusTx.get(0).getPoints()).isEqualTo(100);

        // Process again to verify bonus is not awarded twice
        challengeService.processVerifiedSubmission(sub);
        balance = pointService.getBalance(student1);
        assertThat(balance).isEqualTo(120);
    }

    @Test
    void test17_noBonusWhenConfiguredAsZero() throws Exception {
        Challenge c = createChallenge("No Bonus Challenge", cyclingAction, 1, 0, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(cyclingAction);
        sub.setStatus(SubmissionStatus.REVIEW_REQUIRED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);

        adminReviewService.reviewSubmission(sub.getId(), true, "Approved");

        int balance = pointService.getBalance(student1);
        assertThat(balance).isEqualTo(20); // Only action points

        var txs = pointTransactionRepository.findByUserOrderByCreatedAtDesc(student1);
        var bonusTx = txs.stream().filter(t -> "CHALLENGE_COMPLETION".equals(t.getReferenceType())).toList();
        assertThat(bonusTx).isEmpty();
    }

    @Test
    void test18_existingActionPointsRemainIntact() throws Exception {
        // Award normal action points
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student1);
        sub.setSustainableAction(cyclingAction);
        sub.setStatus(SubmissionStatus.VERIFIED);
        sub.setSubmittedAt(LocalDateTime.now());
        sub = submissionRepository.save(sub);
        pointService.awardPointsForSubmission(sub);

        assertThat(pointService.getBalance(student1)).isEqualTo(20);

        // Now join and complete challenge
        Challenge c = createChallenge("Challenge", cyclingAction, 1, 50, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);
        var participation = challengeService.joinChallenge(student1, c.getId());

        ChallengeParticipation p = participationRepository.findById(participation.id()).orElseThrow();
        pointService.awardBonusPointsForChallengeCompletion(student1, p.getId(), c.getTitle(), c.getBonusPoints());

        // Normal points (20) + Bonus points (50) = 70
        assertThat(pointService.getBalance(student1)).isEqualTo(70);
    }

    // ==========================================
    // LEADERBOARD TESTS (19 - 23)
    // ==========================================

    @Test
    void test19_and_20_and_21_leaderboardReflectsLedgerAndRanks() throws Exception {
        // student1 gets 50 points
        PointTransaction tx1 = new PointTransaction();
        tx1.setUser(student1);
        tx1.setTransactionType(TransactionType.EARN);
        tx1.setPoints(50);
        tx1.setReferenceType("TEST");
        tx1.setReferenceId(UUID.randomUUID().toString());
        tx1.setDescription("Test points");
        pointTransactionRepository.save(tx1);

        // student2 gets 100 points
        PointTransaction tx2 = new PointTransaction();
        tx2.setUser(student2);
        tx2.setTransactionType(TransactionType.EARN);
        tx2.setPoints(100);
        tx2.setReferenceType("TEST");
        tx2.setReferenceId(UUID.randomUUID().toString());
        tx2.setDescription("Test points");
        pointTransactionRepository.save(tx2);

        // Query leaderboard as student1
        mockMvc.perform(get("/api/v1/leaderboard")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entries", hasSize(2)))
                .andExpect(jsonPath("$.entries[0].rank").value(1))
                .andExpect(jsonPath("$.entries[0].studentName").value("Bob Learner"))
                .andExpect(jsonPath("$.entries[0].points").value(100))
                .andExpect(jsonPath("$.entries[1].rank").value(2))
                .andExpect(jsonPath("$.entries[1].studentName").value("Alice Student"))
                .andExpect(jsonPath("$.entries[1].points").value(50))
                .andExpect(jsonPath("$.myRank").value(2))
                .andExpect(jsonPath("$.myPoints").value(50));
    }

    @Test
    void test22_paginationWorks() throws Exception {
        // Query with page size 1
        mockMvc.perform(get("/api/v1/leaderboard?page=0&size=1")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entries", hasSize(1)))
                .andExpect(jsonPath("$.currentPage").value(0))
                .andExpect(jsonPath("$.totalEntries").value(2));
    }

    @Test
    void test23_sensitiveUserInformationIsNotExposed() throws Exception {
        mockMvc.perform(get("/api/v1/leaderboard")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entries[0].email").doesNotExist())
                .andExpect(jsonPath("$.entries[0].password").doesNotExist())
                .andExpect(jsonPath("$.entries[0].passwordHash").doesNotExist())
                .andExpect(jsonPath("$.entries[0].id").doesNotExist());
    }

    // ==========================================
    // SECURITY & IDOR TESTS (24 - 27)
    // ==========================================

    @Test
    void test24_studentCannotAccessOtherStudentParticipation() throws Exception {
        Challenge c = createChallenge("Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);

        challengeService.joinChallenge(student1, c.getId());

        // student2 asks for /my participations -> should not see student1's participation
        mockMvc.perform(get("/api/v1/challenges/my")
                        .with(user(new AuthenticatedUserPrincipal(student2))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void test25_studentCannotModifyProgressDirectly() throws Exception {
        Challenge c = createChallenge("Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), null);
        challengeService.joinChallenge(student1, c.getId());

        // No endpoint accepts arbitrary progressCount
        mockMvc.perform(post("/api/v1/challenges/" + c.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"progressCount\": 999}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void test26_studentCannotCreatePoints() throws Exception {
        // Attempting to post to points endpoints is rejected and point balance cannot be created directly
        mockMvc.perform(post("/api/v1/points/balance")
                        .with(user(new AuthenticatedUserPrincipal(student1)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"points\": 1000}"))
                .andExpect(status().isMethodNotAllowed());

        mockMvc.perform(post("/api/v1/points")
                        .with(user(new AuthenticatedUserPrincipal(student1)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"points\": 1000}"))
                .andExpect(status().isNotFound());

        assertThat(pointService.getBalance(student1)).isEqualTo(0);
    }

    @Test
    void test27_merchantCannotAccessAdminChallengeApis() throws Exception {
        mockMvc.perform(get("/api/v1/admin/challenges")
                        .with(user(new AuthenticatedUserPrincipal(merchant))))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // EDGE CASES
    // ==========================================

    @Test
    void testEdgeCase_futureChallengeCannotBeJoined() throws Exception {
        Challenge future = createChallenge("Future Challenge", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().plusDays(5), LocalDateTime.now().plusDays(15), null);

        mockMvc.perform(post("/api/v1/challenges/" + future.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("not currently open")));
    }

    @Test
    void testEdgeCase_maxParticipantsCapacity() throws Exception {
        Challenge c = createChallenge("Limited Capacity", cyclingAction, 3, 30, ChallengeStatus.ACTIVE,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(10), 1);

        // Student 1 joins final slot
        mockMvc.perform(post("/api/v1/challenges/" + c.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student1))))
                .andExpect(status().isOk());

        // Student 2 tries to join but capacity reached
        mockMvc.perform(post("/api/v1/challenges/" + c.getId() + "/join")
                        .with(user(new AuthenticatedUserPrincipal(student2))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("maximum participant limit")));
    }

    @Test
    void testEdgeCase_invalidChallengeCreationValidation() throws Exception {
        // Target <= 0
        CreateChallengeRequest invalidTarget = new CreateChallengeRequest(
                "Invalid", "desc", LocalDateTime.now(), LocalDateTime.now().plusDays(5),
                ChallengeStatus.ACTIVE, cyclingAction.getId(), 0, 10, null
        );
        mockMvc.perform(post("/api/v1/admin/challenges")
                        .with(user(new AuthenticatedUserPrincipal(admin)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidTarget)))
                .andExpect(status().isBadRequest());

        // Negative bonus
        CreateChallengeRequest invalidBonus = new CreateChallengeRequest(
                "Invalid", "desc", LocalDateTime.now(), LocalDateTime.now().plusDays(5),
                ChallengeStatus.ACTIVE, cyclingAction.getId(), 5, -10, null
        );
        mockMvc.perform(post("/api/v1/admin/challenges")
                        .with(user(new AuthenticatedUserPrincipal(admin)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidBonus)))
                .andExpect(status().isBadRequest());

        // Start date after end date
        CreateChallengeRequest invalidDates = new CreateChallengeRequest(
                "Invalid", "desc", LocalDateTime.now().plusDays(5), LocalDateTime.now(),
                ChallengeStatus.ACTIVE, cyclingAction.getId(), 5, 10, null
        );
        mockMvc.perform(post("/api/v1/admin/challenges")
                        .with(user(new AuthenticatedUserPrincipal(admin)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidDates)))
                .andExpect(status().isBadRequest());
    }
}
