SQL Server Stored Procedure Export & Validation Tool
AI-Assisted Development Contest Entry

---

Project Title
Automated SQL Server Stored Procedure Export and Validation System

Submitted By
Stuart Mayhew

Submission Date
January 25, 2026

Problem Statement

During database conversions and migrations, source databases containing original stored procedures are often overwritten or replaced. DSA needs to:
- Preserve complete inventory of database objects before conversion
- Ensure quality standards are maintained
- Validate procedures against business rules automatically
- Generate compliance reports before deployment

Challenge: Manual extraction and validation of hundreds of procedures is time-consuming, error-prone, and doesn't scale.

Executive Summary

This project demonstrates the effective use of AI-assisted development to rapidly build a production-ready PowerShell solution for managing SQL Server stored procedures during database migrations and conversions. The solution automates two critical processes: exporting procedures with consistent formatting and validating them against business rules—all accomplished through iterative AI prompting without manual coding.
This prompts for Database name (I only have it setup for Windows auth), filters for proc names (or * for all), Schema (* for all)

Key Achievement: Complete end-to-end automation solution built in a single session using 7 focused prompts to an AI assistant, combining export, validation, and compliance checking into a unified workflow.

Solution Overview

A dual-mode PowerShell script that:
1. Exports stored procedures from SQL Server with consistent formatting
2. Validates procedures against business rules - can be run without export
3. Reports violations and compliance status

