# Sistema Web AGUA POTABLE HUACARIZ SAN ANTONIO

Sistema web para la gestión del servicio de agua potable de AGUA POTABLE HUACARIZ SAN ANTONIO.  
Permite administrar clientes, suministros, lecturas, recibos, pagos, tarifas, reportes y generación de códigos QR para identificación de suministros.

---

## 1. Descripción del proyecto

El sistema AGUA POTABLE HUACARIZ SAN ANTONIO permite digitalizar y automatizar los procesos principales de una organización administradora de agua potable, reduciendo el trabajo manual y mejorando el control de clientes, consumos y pagos.

El sistema cuenta con acceso por roles:

- Administrador
- Cliente
- Lecturador

Cada rol tiene funcionalidades específicas dentro del sistema.

---

## 2. Tecnologías utilizadas

### Backend

- Java 21
- Spring Boot
- Spring Security
- JWT
- Spring Data JPA
- PostgreSQL
- Flyway
- Maven

### Frontend Web

- Angular
- TypeScript
- HTML
- SCSS
- RxJS
- XLSX / XLSX-JS-Style para exportación Excel
- Generación e impresión de PDF mediante ventana HTML imprimible

### Base de datos

- PostgreSQL

---

## 3. Estructura del proyecto

```text
Proyecto_Agua/
│
├── backend/
│   └── jass-huacariz-api/
│       ├── src/
│       ├── pom.xml
│       └── mvnw.cmd
│
├── frontend-web/
│   └── jass-huacariz-admin/
│       ├── src/
│       ├── package.json
│       └── angular.json
│
├── database/
│
├── docs/
│
├── postman/
│
└── README.md