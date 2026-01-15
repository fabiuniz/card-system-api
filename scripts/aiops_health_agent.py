import requests

def analyze_health():
    url = "http://localhost:8080/actuator/prometheus"
    try:
        response = requests.get(url)
        lines = response.text.split('\n')
        
        approved = 0
        rejected = 0
        
        for line in lines:
            if 'transactions_total{status="approved",}' in line:
                approved = float(line.split()[-1])
            if 'transactions_total{status="rejected",}' in line:
                rejected = float(line.split()[-1])
        
        total = approved + rejected
        rejection_rate = (rejected / total * 100) if total > 0 else 0
        
        print(f"📊 --- AIOps Health Report ---")
        print(f"✅ Approved: {approved} | ❌ Rejected: {rejected}")
        print(f"📈 Rejection Rate: {rejection_rate:.2f}%")
        
        if rejection_rate > 40:
            print("🚨 ALERT: High rejection rate detected! Check fraud system.")
        else:
            print("🟢 System Status: HEALTHY")
            
    except Exception as e:
        print(f"🚨 Error connecting to API: {e}")

if __name__ == "__main__":
    analyze_health()
