package com.jass.huacariz.config;

import com.jass.huacariz.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/health").permitAll()
				
			.requestMatchers("/api/cliente/**").hasAuthority("CLIENTE")

                        .requestMatchers("/api/clientes/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/sectores/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/tarifas/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/recibos/**").hasAuthority("ADMIN")

                        .requestMatchers(HttpMethod.POST, "/api/lecturas/**").hasAnyAuthority("ADMIN", "LECTURADOR")
                        .requestMatchers(HttpMethod.GET, "/api/lecturas/**").hasAnyAuthority("ADMIN", "LECTURADOR")

                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}