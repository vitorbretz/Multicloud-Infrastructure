# Implementation Plan: Apex Domain Failover

## Overview

Este plano implementa o failover automático para o apex domain (cloud.flog.br) na infraestrutura Terraform multicloud existente. A implementação adiciona registros Route53 e health checks para permitir failover do domínio raiz, mantendo toda a funcionalidade www existente inalterada.

## Tasks

- [x] 1. Extend DNS configuration variables for apex failover
  - Update `dns_config` variable in variables.tf to include apex failover options
  - Add configuration for failover approach (redirect/native/cloudflare)
  - Add apex-specific health check parameters
  - _Requirements: 5.1, 5.4_

- [ ] 2. Implement apex domain primary Route53 record
  - [x] 2.1 Create apex primary Route53 record with CloudFront ALIAS
    - Add aws_route53_record resource for apex domain primary
    - Configure ALIAS to existing CloudFront distribution
    - Set failover routing policy to PRIMARY with set_identifier
    - _Requirements: 1.1, 2.1_
  
  - [ ]* 2.2 Write property test for apex primary DNS resolution
    - **Property 1: Apex Domain Failover Behavior**
    - **Validates: Requirements 1.1**
    
- [ ] 3. Implement health checks for apex domain
  - [ ] 3.1 Create apex primary health check
    - Add aws_route53_health_check resource for CloudFront endpoint
    - Configure HTTPS check with consistent timing parameters (30s interval, 3 failures)
    - Add appropriate tags for apex domain identification
    - _Requirements: 3.1, 3.4, 3.5_
  
  - [ ] 3.2 Create apex secondary health check
    - Add health check for secondary failover solution endpoint
    - Configure parameters consistent with primary health check
    - _Requirements: 3.1, 3.3_
  
  - [ ]* 3.3 Write property test for health check consistency
    - **Property 3: Failover Timing Consistency**
    - **Validates: Requirements 1.4, 2.4, 3.4**

- [ ] 4. Implement secondary failover solution (redirect approach)
  - [ ] 4.1 Create S3 bucket for redirect functionality
    - Add aws_s3_bucket resource for apex domain redirect
    - Configure bucket for website hosting with redirect rules
    - Set redirect target to www subdomain during failover
    - _Requirements: 2.2, 4.2_
  
  - [ ] 4.2 Create apex secondary Route53 record
    - Add aws_route53_record resource for apex domain secondary
    - Configure ALIAS to redirect S3 bucket website endpoint
    - Set failover routing policy to SECONDARY
    - _Requirements: 1.1, 2.2_
  
  - [ ]* 4.3 Write property test for fallback access reliability
    - **Property 8: Fallback Access Reliability**
    - **Validates: Requirements 4.2, 4.3**

- [ ] 5. Checkpoint - Ensure apex domain failover works
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Add infrastructure outputs for apex domain monitoring
  - [ ] 6.1 Add apex-specific output values
    - Add outputs for apex primary and secondary record FQDNs
    - Add outputs for apex health check IDs
    - Add troubleshooting information for apex domain monitoring
    - _Requirements: 5.5_
  
  - [ ]* 6.2 Write example test for infrastructure outputs
    - **Validates: Requirements 5.5**

- [ ] 7. Implement system isolation and preservation tests
  - [ ]* 7.1 Write property test for system isolation
    - **Property 4: System Isolation and Independence**
    - **Validates: Requirements 1.5**
  
  - [ ]* 7.2 Write property test for configuration preservation
    - **Property 5: Configuration Preservation**
    - **Validates: Requirements 2.5, 6.1, 6.3, 6.4**
  
  - [ ]* 7.3 Write property test for independent failover operation
    - **Property 6: Independent Failover Operation**
    - **Validates: Requirements 3.2**

- [ ] 8. Implement rollback and cleanup capabilities
  - [ ] 8.1 Add conditional resource creation based on apex_failover.enabled flag
    - Make all apex-specific resources conditional on configuration flag
    - Ensure clean enable/disable of apex domain failover
    - _Requirements: 6.1, 6.2_
  
  - [ ]* 8.2 Write property test for failover recovery round trip
    - **Property 2: Failover Recovery Round Trip**
    - **Validates: Requirements 1.2, 6.5**
  
  - [ ]* 8.3 Write property test for clean resource management
    - **Property 9: Clean Resource Management**
    - **Validates: Requirements 6.2**

- [ ] 9. Final integration and validation
  - [ ] 9.1 Validate complete Terraform configuration
    - Run terraform plan to ensure no conflicts with existing infrastructure
    - Verify all new resources follow existing naming patterns
    - Confirm health check configurations are consistent
    - _Requirements: 5.2, 5.3_
  
  - [ ]* 9.2 Write property test for health check resource consistency
    - **Property 7: Health Check Resource Consistency**
    - **Validates: Requirements 3.5, 5.3**

- [ ] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation of apex domain failover functionality
- Property tests validate universal correctness properties across all failure scenarios
- Unit tests validate specific examples and Terraform configuration correctness
- The implementation preserves all existing www domain functionality completely unchanged
- All new resources use "apex_" prefix to avoid naming conflicts with existing infrastructure