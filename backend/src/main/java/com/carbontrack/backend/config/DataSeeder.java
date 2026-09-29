package com.carbontrack.backend.config;

import com.carbontrack.backend.action.ActionStatus;
import com.carbontrack.backend.action.CampusZone;
import com.carbontrack.backend.action.CampusZoneRepository;
import com.carbontrack.backend.action.SustainableAction;
import com.carbontrack.backend.action.SustainableActionRepository;
import com.carbontrack.backend.carbon.ActivityType;
import com.carbontrack.backend.carbon.Category;
import com.carbontrack.backend.carbon.EmissionFactor;
import com.carbontrack.backend.carbon.EmissionFactorRepository;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Component
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmissionFactorRepository factorRepository;
    private final CampusZoneRepository campusZoneRepository;
    private final SustainableActionRepository sustainableActionRepository;

    public DataSeeder(UserRepository userRepository, PasswordEncoder passwordEncoder, EmissionFactorRepository factorRepository, CampusZoneRepository campusZoneRepository, SustainableActionRepository sustainableActionRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.factorRepository = factorRepository;
        this.campusZoneRepository = campusZoneRepository;
        this.sustainableActionRepository = sustainableActionRepository;
    }

    @Override
    public void run(String... args) {
        if (!userRepository.existsByEmail("admin@carbontrack.edu")) {
            User admin = new User();
            admin.setEmail("admin@carbontrack.edu");
            admin.setPasswordHash(passwordEncoder.encode("admin_secure_password"));
            admin.setFirstName("System");
            admin.setLastName("Admin");
            admin.setRole(Role.ADMIN);
            userRepository.save(admin);
        }

        if (!userRepository.existsByEmail("merchant@carbontrack.edu")) {
            User merchant = new User();
            merchant.setEmail("merchant@carbontrack.edu");
            merchant.setPasswordHash(passwordEncoder.encode("merchant_secure_password"));
            merchant.setFirstName("Campus");
            merchant.setLastName("Cafe");
            merchant.setRole(Role.MERCHANT);
            userRepository.save(merchant);
        }

        // Seed initial Emission Factors if empty
        if (factorRepository.count() == 0) {
            seedFactor(Category.TRANSPORTATION, ActivityType.PETROL_CAR, "km", "0.192", "DEFRA 2023 (Average Car)");
            seedFactor(Category.TRANSPORTATION, ActivityType.DIESEL_CAR, "km", "0.171", "DEFRA 2023 (Average Car)");
            seedFactor(Category.TRANSPORTATION, ActivityType.PETROL_TWO_WHEELER, "km", "0.113", "DEFRA 2023");
            seedFactor(Category.TRANSPORTATION, ActivityType.PUBLIC_BUS, "km", "0.105", "DEFRA 2023");
            seedFactor(Category.TRANSPORTATION, ActivityType.TRAIN, "km", "0.035", "DEFRA 2023 (National Rail)");
            seedFactor(Category.TRANSPORTATION, ActivityType.WALKING, "km", "0.0", "Zero Emission Assumption");
            seedFactor(Category.TRANSPORTATION, ActivityType.CYCLING, "km", "0.0", "Zero Emission Assumption");

            seedFactor(Category.ELECTRICITY, ActivityType.ELECTRICITY_CONSUMPTION, "kWh", "0.207", "DEFRA 2023 (UK Grid Avg)");

            seedFactor(Category.FOOD, ActivityType.VEGAN, "meals", "0.7", "Example Dev Data - High Level Est");
            seedFactor(Category.FOOD, ActivityType.VEGETARIAN, "meals", "1.2", "Example Dev Data - High Level Est");
            seedFactor(Category.FOOD, ActivityType.MIXED, "meals", "2.0", "Example Dev Data - High Level Est");
            seedFactor(Category.FOOD, ActivityType.NON_VEGETARIAN, "meals", "3.3", "Example Dev Data - High Level Est");

            seedFactor(Category.WASTE, ActivityType.GENERAL_WASTE, "kg", "0.45", "Example Dev Data");
            seedFactor(Category.WASTE, ActivityType.PAPER, "kg", "0.02", "Example Dev Data - Recycled");
            seedFactor(Category.WASTE, ActivityType.PLASTIC, "kg", "0.04", "Example Dev Data - Recycled");
            seedFactor(Category.WASTE, ActivityType.GLASS, "kg", "0.02", "Example Dev Data - Recycled");
            seedFactor(Category.WASTE, ActivityType.METAL, "kg", "0.02", "Example Dev Data - Recycled");
        }

        if (campusZoneRepository.count() == 0) {
            CampusZone zone = new CampusZone();
            zone.setName("Main Campus");
            zone.setLatitude(new BigDecimal("40.7128000"));
            zone.setLongitude(new BigDecimal("-74.0060000"));
            zone.setRadiusMeters(5000);
            zone.setStatus("ACTIVE");
            zone = campusZoneRepository.save(zone);

            if (sustainableActionRepository.count() == 0) {
                seedAction("Tree Plantation", "Plant a tree on campus.", "ENVIRONMENT", ActionStatus.ACTIVE, "100", "PHOTO,GPS,TIMESTAMP", "AI,GEOFENCE", zone);
                seedAction("Recycling", "Recycle materials properly.", "WASTE", ActionStatus.ACTIVE, "20", "PHOTO,GPS,TIMESTAMP", "AI", null);
                seedAction("Cycling to College", "Use a bicycle to commute.", "TRANSPORTATION", ActionStatus.ACTIVE, "50", "GPS,TIMESTAMP", "GEOFENCE", zone);
            }
        }
    }

    private void seedFactor(Category category, ActivityType type, String unit, String value, String source) {
        EmissionFactor factor = new EmissionFactor();
        factor.setCategory(category);
        factor.setActivityType(type);
        factor.setUnit(unit);
        factor.setFactorValue(new BigDecimal(value));
        factor.setSource(source);
        factor.setVersion(1);
        factor.setValidFrom(LocalDateTime.now().minusYears(1)); // Valid since last year
        factorRepository.save(factor);
    }

    private void seedAction(String title, String desc, String category, ActionStatus status, String impact, String evReq, String verReq, CampusZone zone) {
        SustainableAction action = new SustainableAction();
        action.setTitle(title);
        action.setDescription(desc);
        action.setCategory(category);
        action.setStatus(status);
        action.setEstimatedImpact(new BigDecimal(impact));
        action.setEvidenceRequirements(evReq);
        action.setVerificationRequirements(verReq);
        action.setCampusZone(zone);
        action.setStartDate(LocalDateTime.now());
        sustainableActionRepository.save(action);
    }
}
