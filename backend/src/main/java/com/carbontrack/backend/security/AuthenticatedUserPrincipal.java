package com.carbontrack.backend.security;

import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.security.Principal;
import java.util.Collection;
import java.util.Collections;
import java.util.UUID;

public class AuthenticatedUserPrincipal implements UserDetails, Principal {
    private final UUID id;
    private final String email;
    private final Role role;

    public AuthenticatedUserPrincipal(User user) {
        this.id = user.getId();
        this.email = user.getEmail();
        this.role = user.getRole();
    }

    public UUID getId() {
        return id;
    }

    public Role getRole() {
        return role;
    }

    @Override
    public String getName() {
        return email;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override
    public String getPassword() {
        return null; // Not needed for JWT authentication
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
