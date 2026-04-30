# Architecture Layers Reference

This reference helps future rules describe which responsibilities belong in each layer.

## High Level

- UI should render state and collect user intents.
- Domain logic should decide outcomes and validation.

## Lower Level

- Repositories and data sources should expose explicit operations.
- Avoid hiding side effects behind vague names.
