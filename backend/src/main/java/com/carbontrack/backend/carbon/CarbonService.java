package com.carbontrack.backend.carbon;

import com.carbontrack.backend.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class CarbonService {

    private final CarbonActivityRepository activityRepository;
    private final EmissionFactorRepository factorRepository;

    public CarbonService(CarbonActivityRepository activityRepository, EmissionFactorRepository factorRepository) {
        this.activityRepository = activityRepository;
        this.factorRepository = factorRepository;
    }

    @Transactional
    public CarbonActivityDto recordActivity(User user, CarbonActivityRequest request) {
        EmissionFactor factor = factorRepository.findValidFactor(
                request.category(),
                request.activityType(),
                LocalDateTime.now()
        ).orElseThrow(() -> new IllegalArgumentException("No valid emission factor exists for the selected activity type"));

        if (!factor.getUnit().equalsIgnoreCase(request.unit())) {
            throw new IllegalArgumentException("Invalid unit. Expected: " + factor.getUnit());
        }

        CarbonActivity activity = new CarbonActivity();
        activity.setUser(user);
        activity.setCategory(request.category());
        activity.setActivityType(request.activityType());
        activity.setQuantity(request.quantity());
        activity.setUnit(request.unit());
        activity.setActivityDate(request.activityDate());
        activity.setMetadata(request.metadata());

        CarbonCalculation calculation = new CarbonCalculation();
        calculation.setCarbonActivity(activity);
        calculation.setEmissionFactor(factor);
        calculation.setFactorValueUsed(factor.getFactorValue());
        calculation.setFactorVersion(factor.getVersion());
        
        // CO2e = quantity * factor_value
        calculation.setCo2e(request.quantity().multiply(factor.getFactorValue()));
        
        activity.setCalculation(calculation);
        
        CarbonActivity savedActivity = activityRepository.save(activity);
        return CarbonActivityDto.fromEntity(savedActivity);
    }

    @Transactional(readOnly = true)
    public List<CarbonActivityDto> getHistory(User user) {
        return activityRepository.findByUserOrderByActivityDateDescCreatedAtDesc(user)
                .stream()
                .map(CarbonActivityDto::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public CarbonSummaryDto getSummary(User user, LocalDate startDate, LocalDate endDate) {
        List<CarbonActivity> activities = activityRepository.findByUserAndActivityDateBetween(user, startDate, endDate);
        
        BigDecimal total = BigDecimal.ZERO;
        BigDecimal transport = BigDecimal.ZERO;
        BigDecimal electricity = BigDecimal.ZERO;
        BigDecimal food = BigDecimal.ZERO;
        BigDecimal waste = BigDecimal.ZERO;

        for (CarbonActivity activity : activities) {
            BigDecimal co2e = activity.getCalculation() != null ? activity.getCalculation().getCo2e() : BigDecimal.ZERO;
            total = total.add(co2e);
            
            switch (activity.getCategory()) {
                case TRANSPORTATION -> transport = transport.add(co2e);
                case ELECTRICITY -> electricity = electricity.add(co2e);
                case FOOD -> food = food.add(co2e);
                case WASTE -> waste = waste.add(co2e);
            }
        }

        // e.g. "2023-10-01 to 2023-10-31"
        String period = startDate.toString() + " to " + endDate.toString();
        
        return new CarbonSummaryDto(total, transport, electricity, food, waste, period);
    }
}
