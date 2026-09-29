package com.carbontrack.backend.auth;

import com.carbontrack.backend.user.UserDto;

public record AuthResponse(
    String token,
    UserDto user
) {}
