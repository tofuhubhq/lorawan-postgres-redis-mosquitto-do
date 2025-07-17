# 🛰️ ChirpStack Full Stack Deployment

Deploy a production-ready ChirpStack instance with all its core dependencies using OpenTofu. This package includes:

- **ChirpStack Network Server**
- **ChirpStack Application Server**
- **PostgreSQL** for persistent storage
- **Redis** for stream and device session caching
- **Mosquitto (MQTT Broker)** for device uplink/downlink messaging
- **Load Balancer** for routing external traffic

This repository originally targeted DigitalOcean. A new `main_gcp.tf` and accompanying modules
provide experimental support for deploying the stack on Google Cloud Platform.
