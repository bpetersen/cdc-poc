#!/bin/bash
psql -h localhost -d postgres -U postgres -f db-setup.sql
docker-compose exec source-db pg_isready
