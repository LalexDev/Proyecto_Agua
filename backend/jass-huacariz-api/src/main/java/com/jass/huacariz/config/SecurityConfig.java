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


                        // RUTAS PÚBLICAS
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/health").permitAll()

                        .requestMatchers("/uploads/**").permitAll()

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
                        .requestMatchers("/api/auth/**")
                        .permitAll()

                        .requestMatchers("/api/health")
                        .permitAll()


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
                                "/api/lecturas"
                        )
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN",
                                "LECTURADOR",
                                "ROLE_LECTURADOR",
                                "LECTOR",
                                "ROLE_LECTOR"
                        )


                        // ADMIN


                        // ADMIN LECTURAS / HISTORIAL

                        .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/admin/lecturas/**").hasAuthority("ADMIN")

                        // ADMINISTRACIÓN
                        .requestMatchers("/api/clientes/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/usuarios/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/sectores/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/tarifas/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/recibos/**").hasAuthority("ADMIN")
                        .requestMatchers("/api/pagos/**").hasAuthority("ADMIN")


                        .requestMatchers(HttpMethod.GET, "/api/canales-pago/activos").hasAnyAuthority("CLIENTE", "ADMIN")
                        .requestMatchers("/api/canales-pago/**").hasAuthority("ADMIN")

                        .anyRequest().authenticated()

                        .requestMatchers(
                                HttpMethod.POST,
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
                        .requestMatchers(
                                "/api/configuracion-cobranza/**"
                        )
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE CLIENTES
                        .requestMatchers("/api/clientes/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE USUARIOS
                        .requestMatchers("/api/usuarios/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE SECTORES
                        .requestMatchers("/api/sectores/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE TARIFAS
                        .requestMatchers("/api/tarifas/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE RECIBOS
                        .requestMatchers("/api/recibos/**")
                        .hasAnyAuthority(
                                "ADMIN",
                                "ROLE_ADMIN"
                        )

                        // ADMINISTRACIÓN DE PAGOS
                        .requestMatchers("/api/pagos/**")
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


        config.setAllowedOriginPatterns(List.of(
                "http://localhost:4200",
                "http://127.0.0.1:4200",
                "https://*.devtunnels.ms"
        ));

        config.setAllowedMethods(List.of(
                "GET",
                "POST",
                "PUT",
                "PATCH",
                "DELETE",
                "OPTIONS"
        ));

        config.setAllowedHeaders(List.of(
                "Authorization",
                "Content-Type",
                "Accept",
                "Origin",
                "X-Requested-With"
        ));

        config.setExposedHeaders(List.of(
                "Authorization"
        ));

        config.setAllowedOrigins(
                List.of(
                        "http://localhost:4200",
                        "http://127.0.0.1:4200"
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
                        "Accept"
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