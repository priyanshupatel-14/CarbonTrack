package com.carbontrack.backend.verification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

@Configuration
public class AiVerificationConfig {

    private static final Logger log = LoggerFactory.getLogger(AiVerificationConfig.class);

    @Bean
    @ConditionalOnMissingBean(ObjectMapper.class)
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        return mapper;
    }

    @Bean
    public VisionApiClient visionApiClient(
            @Value("${carbontrack.ai.provider:mock}") String provider,
            @Value("${carbontrack.ai.api-key:}") String apiKey,
            @Value("${carbontrack.ai.model:gemini-3.5-flash-lite}") String model,
            @Value("${carbontrack.ai.base-url:}") String baseUrl,
            @Value("${carbontrack.ai.timeout-seconds:${carbontrack.ai.timeout-ms:10}}") int timeoutVal,
            ObjectMapper objectMapper) {

        String selectedProvider = provider != null ? provider.trim().toLowerCase() : "mock";

        int timeoutSeconds = timeoutVal;
        if (timeoutSeconds >= 1000) {
            timeoutSeconds = timeoutSeconds / 1000;
        }
        if (timeoutSeconds <= 0) {
            timeoutSeconds = 10;
        }

        switch (selectedProvider) {
            case "gemini":
                String geminiModel = (model != null && !model.isBlank()) ? model.trim() : "gemini-3.5-flash-lite";
                log.info("Configuring GeminiVisionApiClient with model: {}", geminiModel);
                return new GeminiVisionApiClient(apiKey, geminiModel, baseUrl, timeoutSeconds, objectMapper);
            case "openai":
                String openAiModel = (model != null && !model.isBlank()) ? model.trim() : "gpt-4o-mini";
                log.info("Configuring OpenAiVisionApiClient with model: {}", openAiModel);
                return new OpenAiVisionApiClient(apiKey, openAiModel, baseUrl, timeoutSeconds, objectMapper);
            case "mock":
            default:
                log.info("Configuring MockVisionApiClient");
                return new MockVisionApiClient();
        }
    }

    @Bean
    @Primary
    public EvidenceAnalyzer evidenceAnalyzer(
            @Value("${carbontrack.ai.enabled:false}") boolean aiEnabled,
            @Value("${carbontrack.ai.provider:mock}") String provider,
            AiEvidenceAnalyzer aiEvidenceAnalyzer,
            MockEvidenceAnalyzer mockEvidenceAnalyzer) {

        if (aiEnabled && !"mock".equalsIgnoreCase(provider)) {
            log.info("AI Evidence Verification is ENABLED using provider: {}", provider);
            return aiEvidenceAnalyzer;
        } else {
            log.info("AI Evidence Verification is DISABLED or using mock. Active analyzer: MockEvidenceAnalyzer");
            return mockEvidenceAnalyzer;
        }
    }
}
