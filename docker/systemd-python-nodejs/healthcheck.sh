# Check if backend is responding
backend_health=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")

# Check if frontend is responding
frontend_health=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "000")

if [ "$backend_health" = "200" ] && [ "$frontend_health" = "200" ]; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed - Backend: $backend_health, Frontend: $frontend_health"
    exit 1
fi