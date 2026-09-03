import time
from playwright.sync_api import sync_playwright

GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"

def run_test():
    print("Starting Playwright full user flow test...")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 412, "height": 915})
        page = context.new_page()

        console_logs = []
        page.on("console", lambda msg: console_logs.append(f"[{msg.type}] {msg.text}"))
        page.on("pageerror", lambda err: console_logs.append(f"[pageerror] {err}"))

        print("Navigating to http://127.0.0.1:8080 ...")
        page.goto("http://127.0.0.1:8080", timeout=30000)
        page.wait_for_selector("flt-glass-pane, flutter-view, canvas", timeout=20000)
        time.sleep(2)

        # Set Gemini API Key in localStorage for Flutter Web SharedPreferences
        print("Configuring Gemini API key in localStorage...")
        page.evaluate(f"""() => {{
            localStorage.setItem('flutter.iter_local_gemini_api_key', '"{GEMINI_API_KEY}"');
            localStorage.setItem('flutter.iter_local_departure_city', '"Roma"');
        }}""")

        # Reload so preferences are picked up
        page.reload()
        page.wait_for_selector("flt-glass-pane, flutter-view, canvas", timeout=20000)
        time.sleep(3)

        # 1. Click "Organizza un nuovo viaggio" button (center around x=206, y=325)
        print("Clicking 'Organizza un nuovo viaggio'...")
        page.mouse.click(206, 325)
        time.sleep(2)

        page.screenshot(path="tool/screenshot_chat_opened.png")
        print("Saved screenshot_chat_opened.png")

        # 2. In TripChatScreen, the text input is at the bottom (y ~ 875, x ~ 180)
        print("Focusing input field and typing prompt...")
        page.mouse.click(180, 875)
        time.sleep(0.5)

        # Type the exact user prompt
        prompt = "Vorrei organizzare un viaggio a Budapest dal 5 al 10 dicembre"
        page.keyboard.type(prompt, delay=30)
        time.sleep(0.5)

        # Click send button (around x=380, y=875) or press Enter
        print("Sending prompt...")
        page.keyboard.press("Enter")
        time.sleep(1)
        # Also click the send icon in case Enter doesn't trigger on mobile Flutter
        page.mouse.click(380, 875)

        print("Waiting for Gemini and Fast-flights responses (up to 25s)...")
        # Poll screenshots until response appears or 25s elapsed
        for i in range(12):
            time.sleep(2)
            page.screenshot(path=f"tool/screenshot_chat_waiting_{i}.png")
            # Check console logs for errors
            errors = [l for l in console_logs if "[error]" in l or "[pageerror]" in l]
            if errors:
                print("Observed errors:", errors[-3:])

        page.screenshot(path="tool/screenshot_chat_result.png")
        print("Final result screenshot saved to tool/screenshot_chat_result.png")

        print("\nAll captured console logs:")
        for log in console_logs[-20:]:
            print("  ", log)

        browser.close()
    print("Playwright flow test completed.")

if __name__ == "__main__":
    run_test()
