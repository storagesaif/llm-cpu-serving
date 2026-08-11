cd /Users/saifadil/llm-cpu-serving

cat > helm/values.yaml << 'EOF'
# OCP username of the person deploying this chart (oc whoami).
# Used to set the workbench owner annotation so the RHOAI dashboard generates the correct link.
username: ""

images:
  vllmRuntime: "registry.redhat.io/rhaii/vllm-cpu-rhel9@sha256:cf6577f6d526561651df5390aad916c53820a18a1659e3fb39c1c5a62aef0e3c"
  llamaStack: "registry.redhat.io/rhoai/odh-llama-stack-core-rhel9@sha256:d0375eb3cb815b9e750efaee4809715b3ebf64a126ca179dc3da8b9b1f36443a"
  anythingllm: "quay.io/rh-aiservices-bu/anythingllm-workbench:1.9.1"

model:
  storageUri: "oci://quay.io/rh-aiservices-bu/tinyllama:1.0"
  name: "tinyllama"
  maxModelLen: 2048
  maxOutputTokens: 512

resources:
  inference:
    requests:
      cpu: "4"
      memory: "8Gi"
    limits:
      cpu: "8"
      memory: "16Gi"

# Storage class for the AnythingLLM workbench PVC.
# IBM Cloud ROKS with ODF: ocs-storagecluster-cephfs
# AWS ROSA / self-managed: gp3-csi
# Leave empty ("") to use the cluster default.
storageClassName: "ocs-storagecluster-cephfs"

pvc:
  size: 5Gi
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem

aiLifecoach:
  workspace:
    name: "Assistant to the HR Representative"
    systemPrompt: |
      You are an assistant to an HR representative in a large U.S. bank (financial services institution).
      Your role is to help HR professionals handle people-related issues in a highly regulated environment,
      balancing employee experience with strict conduct, risk, and compliance requirements.

      Domain context:
      - You operate in U.S. financial services, where regulators (e.g., OCC, Federal Reserve, FDIC, CFPB, SEC, FINRA)
        and internal compliance functions place strong emphasis on culture, conduct risk, and documentation.
      - Employees may be subject to background checks, licensing/registration (e.g., FINRA), personal trading rules,
        confidentiality, and strict codes of conduct.

      Key areas of expertise:
      - Employee relations and conduct issues in a regulated banking environment
      - HR's role in fostering a strong compliance and risk culture
      - Performance management, underperformance, and documentation for regulated roles
      - Hiring and onboarding in banking (background checks, FCRA, I-9, BSA/AML-sensitive roles)
      - Workplace behavior: bullying, harassment, discrimination, retaliation, and "speak-up" culture
      - Leave, working time, and attendance issues, with attention to fairness and consistency
      - Whistleblowing, investigations, and when to involve Legal, Compliance, or Audit
      - Training, certifications, and fitness/appropriateness for sensitive roles
      - Change management, restructuring, and communication in financial institutions

      Always provide:
      - Clear, practical next steps for the HR representative (including who to loop in: Legal, Compliance, Risk, ER)
      - Options with pros and cons, highlighting compliance, conduct, and reputational risk
      - Recommendations that are fair, consistent, non-discriminatory, and well-documented
      - Reminders about:
        - Confidentiality and need-to-know access
        - Maintaining accurate HR records and investigation notes
        - Escalating potential regulatory, legal, or ethics issues promptly

      Style:
      - Be concise but comprehensive.
      - Use bullet points when helpful.
      - Ask clarifying questions when needed to give context-aware guidance (e.g., state, union status, role type).
      - Do NOT provide definitive legal advice. Instead, flag legal and regulatory risk and recommend consulting:
        - Internal Legal, Compliance, or Employee Relations teams
        - External counsel where appropriate.
      - When regulations could differ by state or regulator, explicitly call out that local rules may vary.

rag:
  seedDocuments:
    - filename: strong-compliance-culture.txt
      url: https://crosscheckcompliance.com/resources/articles/strong-compliance-culture/
    - filename: understanding-employment-laws.txt
      url: https://www.sunflowerbank.com/about-us/resource-articles/understanding-employment-laws/
    - filename: anti-harassment-training-guide.txt
      url: https://compliancy-group.com/anti-harassment-training-guide/
    - filename: hr-compliance-financial-services.txt
      url: https://www.metricstream.com/learn/hr-compliance.html
EOF

cat > README.md << 'EOF'
# Serve a lightweight HR assistant

![chat-example.png](docs/images/chat-example.png)

Replace hours spent searching policy documents with higher-value relational work.

## Detailed description

The *Assistant to the HR Representative* is a lightweight quickstart designed to
give HR Representatives in Financial Services a trusted sounding board for discussions and decisions.
Chat with this assistant for quick insights and actionable advice.

This quickstart was designed for environments where GPUs are not available or necessary, making it
ideal for lightweight inference use cases, prototyping, or constrained environments. By making the
most of vLLM on CPU-based infrastructure, this Assistant can be deployed to almost any OpenShift AI
environment.

This quickstart includes a Helm chart for deploying:

- An OpenShift AI Project.
- vLLM with CPU support running an instance of TinyLlama.
- A LlamaStack RAG pipeline seeded with HR compliance documents.
- AnythingLLM, a versatile chat interface, running as a workbench connected to vLLM.

---

## Architecture diagrams

![architecture.png](docs/images/architecture.png)

---

## Requirements

### Minimum hardware requirements

- No GPU needed! 🤖
- 4 cores
- 8 Gi memory
- Storage: 5Gi

### Recommended hardware requirements

- No GPU needed! 🤖
- 8 cores
- 16 Gi memory
- Storage: 5Gi

> **Note:** This version is compiled for Intel CPUs (preferably with AVX-512 enabled).
> Example AWS instance: [m6i.4xlarge](https://instances.vantage.sh/aws/ec2/m6i.4xlarge)

---

## Prerequisites — Install these BEFORE deploying

> ⚠️ All four steps below must be completed before running `helm install`.
> The Helm chart creates resources that depend on all of them.

### 1. Red Hat OpenShift Serverless

Required by KServe (model serving).
Install from OperatorHub → search **"OpenShift Serverless"** → install to all namespaces.

Wait for:
```bash
oc get csv -A | grep serverless        # must show: Succeeded
oc get knativeserving -n knative-serving   # READY = True