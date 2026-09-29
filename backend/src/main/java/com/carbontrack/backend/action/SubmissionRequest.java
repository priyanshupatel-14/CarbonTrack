package com.carbontrack.backend.action;

import java.time.LocalDateTime;
import java.util.UUID;

public record SubmissionRequest(
        UUID sustainableActionId,
        LocalDateTime clientTimestamp
) {}
