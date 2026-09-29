package com.carbontrack.backend;

import com.carbontrack.backend.action.*;
import com.carbontrack.backend.points.*;
import com.carbontrack.backend.rewards.*;
import com.carbontrack.backend.user.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.junit.jupiter.Container;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class Phase5IntegrationTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SustainableActionRepository actionRepository;

    @Autowired
    private ActionSubmissionRepository submissionRepository;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @Autowired
    private RewardRepository rewardRepository;

    @Autowired
    private RewardRedemptionRepository redemptionRepository;

    @Autowired
    private CouponRepository couponRepository;

    @Autowired
    private RewardService rewardService;

    @Autowired
    private PointService pointService;

    private User student;
    private User admin;
    private User merchant;
    private User merchant2;
    private SustainableAction action;
    private Reward activeReward;
    private Reward outOfStockReward;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();

        couponRepository.deleteAll();
        redemptionRepository.deleteAll();
        rewardRepository.deleteAll();
        pointTransactionRepository.deleteAll();
        jdbcTemplate.execute("DELETE FROM challenge_progress_events");
        jdbcTemplate.execute("DELETE FROM challenge_participations");
        jdbcTemplate.execute("DELETE FROM challenges");
        jdbcTemplate.execute("DELETE FROM verification_results");
        jdbcTemplate.execute("DELETE FROM evidence");
        submissionRepository.deleteAll();
        actionRepository.deleteAll();
        userRepository.deleteAll();

        student = createUser("student@test.com", Role.STUDENT);
        admin = createUser("admin@test.com", Role.ADMIN);
        merchant = createUser("merchant@test.com", Role.MERCHANT);
        merchant2 = createUser("merchant2@test.com", Role.MERCHANT);

        action = new SustainableAction();
        action.setTitle("Test Action");
        action.setDescription("Desc");
        action.setCategory("WASTE");
        action.setStatus(ActionStatus.ACTIVE);
        action.setEstimatedImpact(BigDecimal.TEN);
        action.setPointsReward(100);
        action = actionRepository.save(action);

        activeReward = new Reward();
        activeReward.setName("Coffee");
        activeReward.setDescription("Free Coffee");
        activeReward.setPointsRequired(50);
        activeReward.setInventory(10);
        activeReward.setStatus(RewardStatus.ACTIVE);
        activeReward.setMerchant(merchant);
        activeReward = rewardRepository.save(activeReward);
        
        outOfStockReward = new Reward();
        outOfStockReward.setName("Mug");
        outOfStockReward.setPointsRequired(50);
        outOfStockReward.setInventory(0);
        outOfStockReward.setStatus(RewardStatus.OUT_OF_STOCK);
        outOfStockReward.setMerchant(merchant);
        outOfStockReward = rewardRepository.save(outOfStockReward);
    }

    private User createUser(String email, Role role) {
        User u = new User();
        u.setEmail(email);
        u.setPasswordHash("hashed");
        u.setFirstName(role.name());
        u.setLastName("Test");
        u.setRole(role);
        return userRepository.save(u);
    }

    private void awardInitialPoints(User user, int amount) {
        PointTransaction tx = new PointTransaction();
        tx.setUser(user);
        tx.setPoints(amount);
        tx.setTransactionType(TransactionType.ADJUSTMENT);
        tx.setReferenceType("TEST_INIT");
        tx.setReferenceId(UUID.randomUUID().toString());
        pointTransactionRepository.save(tx);
    }

    @Test
    void test1_test3_test4_verifyActionAwardsPointsOnce() throws Exception {
        // Setup pending submission
        ActionSubmission sub = new ActionSubmission();
        sub.setUser(student);
        sub.setSustainableAction(action);
        sub.setStatus(SubmissionStatus.REVIEW_REQUIRED);
        sub = submissionRepository.save(sub);

        // Admin approves
        mockMvc.perform(post("/api/v1/admin/submissions/" + sub.getId() + "/approve")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(admin)))
                .param("reason", "Looks good"))
                .andExpect(status().isOk());

        // Assert points awarded
        int balance = pointService.getBalance(student);
        assertThat(balance).isEqualTo(100);

        // Try approving again
        mockMvc.perform(post("/api/v1/admin/submissions/" + sub.getId() + "/approve")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(admin)))
                .param("reason", "Looks good"))
                .andExpect(status().isBadRequest()); // Handled as 400 (IllegalStateException)

        // Balance should still be 100
        balance = pointService.getBalance(student);
        assertThat(balance).isEqualTo(100);
    }

    @Test
    void test9_test10_test11_test12_test13_redeemReward() throws Exception {
        // Insufficient points
        mockMvc.perform(post("/api/v1/rewards/" + activeReward.getId() + "/redeem")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(student))))
                .andExpect(status().isBadRequest()); // Handled by GlobalExceptionHandler

        // Award points
        awardInitialPoints(student, 50);

        // Redeem active reward
        mockMvc.perform(post("/api/v1/rewards/" + activeReward.getId() + "/redeem")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(student))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").isNotEmpty());

        // Balance should be 0
        assertThat(pointService.getBalance(student)).isEqualTo(0);

        // Inventory should be 9
        Reward r = rewardRepository.findById(activeReward.getId()).orElseThrow();
        assertThat(r.getInventory()).isEqualTo(9);

        // Try redeeming out of stock
        awardInitialPoints(student, 50);
        mockMvc.perform(post("/api/v1/rewards/" + outOfStockReward.getId() + "/redeem")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(student))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void test17_test18_test20_validateAndConsumeCoupon() throws Exception {
        // Create a coupon for student
        awardInitialPoints(student, 50);
        CouponDto coupon = rewardService.redeemReward(student, activeReward.getId());

        // Merchant validates
        mockMvc.perform(post("/api/v1/merchant/coupons/validate")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(merchant)))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\": \"" + coupon.code() + "\"}"))
                .andExpect(status().isOk());

        // Merchant2 tries to validate (should fail)
        mockMvc.perform(post("/api/v1/merchant/coupons/validate")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(merchant2)))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\": \"" + coupon.code() + "\"}"))
                .andExpect(status().isForbidden()); // handled as SecurityException -> 403 (or 400 if mapped to bad request, but should fail)
        
        // Merchant consumes
        mockMvc.perform(post("/api/v1/merchant/coupons/consume")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(merchant)))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\": \"" + coupon.code() + "\"}"))
                .andExpect(status().isOk());

        // Merchant tries to consume again
        mockMvc.perform(post("/api/v1/merchant/coupons/consume")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(new com.carbontrack.backend.security.AuthenticatedUserPrincipal(merchant)))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\": \"" + coupon.code() + "\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testConcurrency_InventoryDoesNotGoNegative() throws Exception {
        awardInitialPoints(student, 500); // Plenty of points
        outOfStockReward.setInventory(1); // Only 1 left
        outOfStockReward.setStatus(RewardStatus.ACTIVE);
        rewardRepository.save(outOfStockReward);

        int threadCount = 5;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch latch = new CountDownLatch(1);
        CountDownLatch done = new CountDownLatch(threadCount);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger failCount = new AtomicInteger(0);

        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    latch.await();
                    rewardService.redeemReward(student, outOfStockReward.getId());
                    successCount.incrementAndGet();
                } catch (Exception e) {
                    failCount.incrementAndGet();
                } finally {
                    done.countDown();
                }
            });
        }

        latch.countDown(); // start all threads
        done.await(); // wait for all to finish

        assertThat(successCount.get()).isEqualTo(1); // Only one should succeed
        assertThat(failCount.get()).isEqualTo(threadCount - 1);
        
        Reward r = rewardRepository.findById(outOfStockReward.getId()).orElseThrow();
        assertThat(r.getInventory()).isEqualTo(0);
        assertThat(r.getStatus()).isEqualTo(RewardStatus.OUT_OF_STOCK);
    }
}
