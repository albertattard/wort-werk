apiVersion: v1
kind: Namespace
metadata:
  name: ${APP_NAMESPACE}
  labels:
    app.kubernetes.io/name: wortwerk
    app.kubernetes.io/part-of: wortwerk
    app.kubernetes.io/component: runtime
    app.kubernetes.io/environment: production
