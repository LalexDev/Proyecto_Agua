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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/health").permitAll()

                        // PORTAL CLIENTE
                        .requestMatchers("/api/cliente/**").hasAuthority("CLIENTE")

                        // PORTAL LECTURADOR
                        .requestMatchers("/api/lecturador/**").hasAuthority("LECTURADOR")

                        // LECTURAS: ADMIN Y LECTURADOR
                        .requestMatchers(HttpMethod.POST, "/api/lecturas").hasAnyAuthority("ADMIN", "LECTURADOR")
                        .requestMatchers(HttpMethod.POST, "/api/lecturas/mantenimiento").hasAnyAuthority("ADMIN", "LECTURADOR")
                        .requestMatchers(HttpMethod.GET, "/api/lecturas/**").hasAnyAuthority("ADMIN", "LECTURADOR")

                        // ADMINISTRACIÓN
                        .requestMatchers("/api/clientes/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/usuarios/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/sectores/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/tarifas/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/recibos/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/pagos/**").hasAuthority("ADMIN")

                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        config.setAllowedOrigins(List.of("http://localhost:4200"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}