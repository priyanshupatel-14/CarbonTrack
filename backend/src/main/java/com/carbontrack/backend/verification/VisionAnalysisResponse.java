package com.carbontrack.backend.verification;

import java.util.List;

public record VisionAnalysisResponse(
    boolean relevant,
    double confidence,
    List<String> detectedElements,
    String reasoning,
    String fraudRisk,
    boolean possibleAiGenerated,
    boolean possibleManipulation,
    boolean possibleRecapture,
    List<String> fraudIndicators,
    String provider,
    String model,
    String rawResponse
) {
    // Backwards-compatible constructor for 8-argument callers
    public VisionAnalysisResponse(
            boolean relevant,
            double confidence,
            List<String> detectedElements,
            String reasoning,
            boolean suspicious,
            String provider,
            String model,
            String rawResponse
    ) {
        this(
            relevant,
            confidence,
            detectedElements,
            reasoning,
            suspicious ? "HIGH" : "LOW",
            suspicious,
            suspicious,
            false,
            suspicious ? List.of("Suspicious visual indicators detected") : List.of(),
            provider,
            model,
            rawResponse
        );
    }

    // Backwards-compatible constructor for 7-argument callers
    public VisionAnalysisResponse(
            boolean relevant,
            double confidence,
            List<String> detectedElements,
            String reasoning,
            boolean suspicious,
            String provider,
            String model
    ) {
        this(relevant, confidence, detectedElements, reasoning, suspicious, provider, model, "");
    }

    // Convenience method for backwards compatibility with response.suspicious()
    public boolean suspicious() {
        return !"LOW".equalsIgnoreCase(fraudRisk)
                || possibleAiGenerated
                || possibleManipulation
                || possibleRecapture
                || (fraudIndicators != null && !fraudIndicators.isEmpty());
    }
}
