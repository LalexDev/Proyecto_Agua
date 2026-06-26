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
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        http
                .cors(cors ->
                        cors.configurationSource(corsConfigurationSource())
                )
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )
                .authorizeHttpRequests(auth -> auth

                        // PREFLIGHT CORS
                        .requestMatchers(
                                HttpMethod.OPTIONS,
                                "/**"
                        )
                        .permitAll()

                        // RUTAS PÚBLICAS
                        .requestMatchers(
                                "/api/auth/**",
                                "/api/health",
                                "/uploads/**"
                        )
                        .permitAll()

                        // CANALES DE PAGO ACTIVOS PARA CLIENTE Y ADMIN
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/canales-pago/activos"
                        )
                        .hasAnyAuthority(
                                "CLIENTE",
                                "ROLE_CLIENTE",
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // PORTAL CLIENTE
                        .requestMatchers("/api/cliente/**")
                        .hasAnyAuthority(
                                "CLIENTE",
                                "ROLE_CLIENTE",
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // PORTAL LECTURADOR
                        .requestMatchers("/api/lecturador/**")
                        .hasAnyAuthority(
                                "LECTURADOR",
                                "ROLE_LECTURADOR",
                                "LECTOR",
                                "ROLE_LECTOR",
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // REGISTRAR LECTURAS
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/lecturas",
                                "/api/lecturas/**"
                        )
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN",
                                "LECTURADOR",
                                "ROLE_LECTURADOR",
                                "LECTOR",
                                "ROLE_LECTOR"
                        )

                        // CONSULTAR LECTURAS
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/lecturas",
                                "/api/lecturas/**"
                        )
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN",
                                "LECTURADOR",
                                "ROLE_LECTURADOR",
                                "LECTOR",
                                "ROLE_LECTOR"
                        )

                        // CONFIGURACIÓN DE COBRANZA
                        .requestMatchers("/api/configuracion-cobranza/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE CANALES DE PAGO
                        .requestMatchers("/api/canales-pago/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // RUTAS ADMINISTRATIVAS
                        .requestMatchers(
                                "/api/admin/**",
                                "/api/clientes/**",
                                "/api/usuarios/**",
                                "/api/sectores/**",
                                "/api/tarifas/**",
                                "/api/recibos/**",
                                "/api/pagos/**"
                        )
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // CUALQUIER OTRA RUTA
                        .anyRequest()
                        .authenticated()
                )
                .addFilterBefore(
                        jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {

        CorsConfiguration config = new CorsConfiguration();

        config.setAllowedOriginPatterns(
                List.of(
                        "http://localhost:4200",
                        "http://127.0.0.1:4200",
                        "https://*.devtunnels.ms"
                )
        );

        config.setAllowedMethods(
                List.of(
                        "GET",
                        "POST",
                        "PUT",
                        "PATCH",
                        "DELETE",
                        "OPTIONS"
                )
        );

        config.setAllowedHeaders(
                List.of(
                        "Authorization",
                        "Content-Type",
                        "Accept",
                        "Origin",
                        "X-Requested-With"
                )
        );

        config.setExposedHeaders(
                List.of(
                        "Authorization",
                        "Content-Disposition"
                )
        );

        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration(
                "/**",
                config
        );

        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}