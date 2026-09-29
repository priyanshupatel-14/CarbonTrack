package com.carbontrack.backend;

import com.carbontrack.backend.auth.AuthService;
import com.carbontrack.backend.auth.LoginRequest;
import com.carbontrack.backend.auth.RegisterRequest;
import com.carbontrack.backend.carbon.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Testcontainers
@Transactional
class CarbonIntegrationTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private AuthService authService;

    @Autowired
    private EmissionFactorRepository factorRepository;

    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private String token1;
    private String token2;

    @BeforeEach
    void setup() {
        this.mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
                
        // Register students if they don't exist
        try {
            authService.register(new RegisterRequest("student1@test.com", "password", "S1", "Test"));
        } catch (Exception ignored) {}
        try {
            authService.register(new RegisterRequest("student2@test.com", "password", "S2", "Test"));
        } catch (Exception ignored) {}
        
        token1 = authService.login(new LoginRequest("student1@test.com", "password")).token();
        token2 = authService.login(new LoginRequest("student2@test.com", "password")).token();
    }

    @Test
    void testValidCalculations() throws Exception {
        // 1. Transportation
        CarbonActivityRequest transport = new CarbonActivityRequest(Category.TRANSPORTATION, ActivityType.PETROL_CAR, new BigDecimal("10.5"), "km", LocalDate.now(), null);
        mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(transport)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.co2e").value(10.5 * 0.192));

        // 2. Electricity
        CarbonActivityRequest electricity = new CarbonActivityRequest(Category.ELECTRICITY, ActivityType.ELECTRICITY_CONSUMPTION, new BigDecimal("100"), "kWh", LocalDate.now(), null);
        mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(electricity)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.co2e").value(100 * 0.207));

        // 3. Food
        CarbonActivityRequest food = new CarbonActivityRequest(Category.FOOD, ActivityType.VEGAN, new BigDecimal("2"), "meals", LocalDate.now(), null);
        mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(food)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.co2e").value(2 * 0.7));

        // 4. Waste
        CarbonActivityRequest waste = new CarbonActivityRequest(Category.WASTE, ActivityType.PLASTIC, new BigDecimal("5"), "kg", LocalDate.now(), null);
        mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(waste)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.co2e").value(5 * 0.04));
    }

    @Test
    void testMissingEmissionFactor() throws Exception {
        // 5. Missing factor (wrong unit not caught by factor missing, but wrong type for category will be missing)
        CarbonActivityRequest invalidType = new CarbonActivityRequest(Category.TRANSPORTATION, ActivityType.VEGAN, new BigDecimal("10"), "km", LocalDate.now(), null);
        mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidType)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testInvalidQuantity() throws Exception {
        // 6. Invalid quantity
        CarbonActivityRequest invalidQty = new CarbonActivityRequest(Category.TRANSPORTATION, ActivityType.PETROL_CAR, new BigDecimal("-5"), "km", LocalDate.now(), null);
        mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidQty)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testHistoricalReproducibilityAndIsolation() throws Exception {
        // Record activity for student 1
        CarbonActivityRequest req = new CarbonActivityRequest(Category.TRANSPORTATION, ActivityType.PETROL_CAR, new BigDecimal("10"), "km", LocalDate.now(), null);
        MvcResult res = mockMvc.perform(post("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        
        String responseBody = res.getResponse().getContentAsString();
        CarbonActivityDto dto = objectMapper.readValue(responseBody, CarbonActivityDto.class);
        BigDecimal originalCo2e = dto.co2e();
        
        // Update emission factor version
        EmissionFactor oldFactor = factorRepository.findValidFactor(Category.TRANSPORTATION, ActivityType.PETROL_CAR, LocalDateTime.now()).get();
        oldFactor.setValidTo(LocalDateTime.now().minusSeconds(1));
        factorRepository.save(oldFactor);
        
        EmissionFactor newFactor = new EmissionFactor();
        newFactor.setCategory(Category.TRANSPORTATION);
        newFactor.setActivityType(ActivityType.PETROL_CAR);
        newFactor.setUnit("km");
        newFactor.setFactorValue(new BigDecimal("0.500"));
        newFactor.setSource("New Source");
        newFactor.setVersion(2);
        newFactor.setValidFrom(LocalDateTime.now());
        factorRepository.save(newFactor);
        
        // 7. Verify historical remains unchanged
        mockMvc.perform(get("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].co2e").value(originalCo2e.doubleValue()))
                .andExpect(jsonPath("$[0].factorVersion").value(1));
                
        // 8. Student cannot access another's records
        mockMvc.perform(get("/api/v1/carbon/activities")
                .header("Authorization", "Bearer " + token2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty()); // Student 2 has no activities
    }

    @Test
    void testSummaryAndDateRange() throws Exception {
        // Submit 2 activities on different dates for student 2
        CarbonActivityRequest req1 = new CarbonActivityRequest(Category.ELECTRICITY, ActivityType.ELECTRICITY_CONSUMPTION, new BigDecimal("100"), "kWh", LocalDate.of(2023, 1, 15), null);
        CarbonActivityRequest req2 = new CarbonActivityRequest(Category.FOOD, ActivityType.VEGETARIAN, new BigDecimal("10"), "meals", LocalDate.of(2023, 2, 15), null);
        
        mockMvc.perform(post("/api/v1/carbon/activities").header("Authorization", "Bearer " + token2).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(req1)));
        mockMvc.perform(post("/api/v1/carbon/activities").header("Authorization", "Bearer " + token2).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(req2)));
        
        // 10. Summary aggregation & 11. Date filtering
        // Jan only
        mockMvc.perform(get("/api/v1/carbon/summary?startDate=2023-01-01&endDate=2023-01-31")
                .header("Authorization", "Bearer " + token2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.electricityCo2e").value(100 * 0.207))
                .andExpect(jsonPath("$.foodCo2e").value(0))
                .andExpect(jsonPath("$.totalCo2e").value(100 * 0.207));
                
        // Feb only
        mockMvc.perform(get("/api/v1/carbon/summary?startDate=2023-02-01&endDate=2023-02-28")
                .header("Authorization", "Bearer " + token2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.electricityCo2e").value(0))
                .andExpect(jsonPath("$.foodCo2e").value(10 * 1.2))
                .andExpect(jsonPath("$.totalCo2e").value(10 * 1.2));
                
        // Both
        mockMvc.perform(get("/api/v1/carbon/summary?startDate=2023-01-01&endDate=2023-02-28")
                .header("Authorization", "Bearer " + token2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.electricityCo2e").value(100 * 0.207))
                .andExpect(jsonPath("$.foodCo2e").value(10 * 1.2));
    }
}
