# 🛰️ ChirpStack Full Stack Deployment on Google Cloud

This project contains OpenTofu configurations to deploy a full ChirpStack stack on **Google Cloud Platform (GCP)**. The deployment includes:

- **ChirpStack Network Server**
- **ChirpStack Application Server**
- **PostgreSQL** backed by Cloud SQL
- **Redis** using Memorystore
- **Mosquitto** MQTT broker on a Compute Instance
- **HTTP Load Balancer**

The legacy DigitalOcean configuration is still available in `main.tf`. To deploy on GCP use the `gcp_main.tf` entry point and provide the required variables.
