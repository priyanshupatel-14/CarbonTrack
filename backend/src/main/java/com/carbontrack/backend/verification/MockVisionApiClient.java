package com.carbontrack.backend.verification;

import java.util.ArrayList;
import java.util.List;

public class MockVisionApiClient implements VisionApiClient {

    private boolean returnValid = true;
    private double confidence = 0.95;
    private List<String> detectedElements = List.of("sustainable practice", "environment");
    private String reasoning = "Visual evidence is consistent with the sustainable action.";
    private boolean suspicious = false;

    private String fraudRisk = "LOW";
    private boolean possibleAiGenerated = false;
    private boolean possibleManipulation = false;
    private boolean possibleRecapture = false;
    private List<String> fraudIndicators = new ArrayList<>();

    public MockVisionApiClient() {}

    public MockVisionApiClient(boolean returnValid, double confidence, String reasoning) {
        this.returnValid = returnValid;
        this.confidence = confidence;
        this.reasoning = reasoning;
    }

    @Override
    public String getProviderName() {
        return "mock";
    }

    @Override
    public VisionAnalysisResponse analyze(byte[] imageBytes, String mimeType, String prompt) {
        return new VisionAnalysisResponse(
                returnValid,
                confidence,
                detectedElements,
                reasoning,
                suspicious ? "HIGH" : fraudRisk,
                suspicious || possibleAiGenerated,
                suspicious || possibleManipulation,
                possibleRecapture,
                fraudIndicators.isEmpty() && suspicious ? List.of("Suspicious visual indicators") : fraudIndicators,
                "mock",
                "mock-vision-v1",
                ""
        );
    }

    public void setReturnValid(boolean returnValid) {
        this.returnValid = returnValid;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }

    public void setDetectedElements(List<String> detectedElements) {
        this.detectedElements = detectedElements;
    }

    public void setReasoning(String reasoning) {
        this.reasoning = reasoning;
    }

    public void setSuspicious(boolean suspicious) {
        this.suspicious = suspicious;
    }

    public void setFraudRisk(String fraudRisk) {
        this.fraudRisk = fraudRisk;
    }

    public void setPossibleAiGenerated(boolean possibleAiGenerated) {
        this.possibleAiGenerated = possibleAiGenerated;
    }

    public void setPossibleManipulation(boolean possibleManipulation) {
        this.possibleManipulation = possibleManipulation;
    }

    public void setPossibleRecapture(boolean possibleRecapture) {
        this.possibleRecapture = possibleRecapture;
    }

    public void setFraudIndicators(List<String> fraudIndicators) {
        this.fraudIndicators = fraudIndicators != null ? fraudIndicators : new ArrayList<>();
    }
}
