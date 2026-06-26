#!/usr/bin/env python3
"""Generate cover image using 小黑 style + Tongyi-MAI/Z-Image-Turbo.
Uses the ORIGINAL ian-xiaohei prompt template unchanged."""
import subprocess, json, os, time

API_KEY = os.environ.get("SILICONFLOW_API_KEY", "")

SHOTS = {
    "hearing-journey": ("听见", "概念隐喻", "小黑坐在纸箱声音机前，漏斗当耳，声音碎片掉进机器，机器吐出纸条", "纸箱机 / 漏斗 / 声波 / 纸条 / 小黑", "漏斗耳 / 转文字"),
    "llm-migration": ("四次切换", "地图路线", "小黑站在四岔路口，三条路插'不通'牌，第四路通向亮灯机器", "岔路 / 路牌 / 亮灯机 / 小黑", "四次 / 不通 / 成了"),
    "infrastructure-memory": ("三层记忆", "方法分层", "小黑用积木搭三层架，每层放一本书", "积木架 / 书 / 小黑", "三层 / 好找"),
    "pitfalls-and-improvements": ("边修边长", "前后对比", "小黑趴图纸上，弯路有红叉，拿橡皮擦叉画勾", "图纸 / 弯路 / 红叉 / 橡皮 / 小黑", "有坑 / 修好"),
    "project-kickoff-ts-rewrite": ("从乱到整", "前后对比", "小黑蹲地上，乱线团一根根理整齐绕成圆盘", "线团 / 圆盘 / 小黑", "乱变整 / 理好"),
}

def build_prompt(theme, stype, idea, elements, labels):
    return f"""Generate one standalone 16:9 horizontal Chinese article illustration.

Visual DNA:
Pure white background. Minimalist black hand-drawn line art. Slightly wobbly pen lines. Lots of empty white space. Sparse red/orange/blue handwritten Chinese annotations. Clean absurd product-sketch feeling. No gradients, no shadows, no paper texture, no complex background, no commercial vector style, no PPT infographic look, no cute mascot poster, no children's illustration, no realistic UI.

Recurring IP character required:
小黑, a small solid-black absurd creature with white dot eyes, tiny thin legs, blank serious expression, slightly uneven hand-drawn body shape. 小黑 must perform the core conceptual action, not decorate the scene. Make 小黑 serious, deadpan, and slightly bizarre, not cute.

Theme:
{theme}

Structure type:
{stype}

Core idea:
{idea}

Suggested elements:
{elements}

Chinese handwritten labels:
{labels}

Color use:
Black for main line art and 小黑. Orange for main flow/path/arrows. Red only for key warnings/problems/results. Blue only for secondary notes or feedback/system state.

Constraints:
One image explains only one core structure. Keep the main subject around 40%-60% of the canvas. Preserve at least 35% blank white space. Use at most 5-8 short handwritten Chinese labels. Do not write a title in the top-left corner. Do not write the structure type on the image. Do not make it a formal diagram, course slide, or dense explainer. Do not copy prior examples or reuse known case compositions unless explicitly requested; invent a fresh visual metaphor for this specific article. It should be clear but not instructional, interesting but not childish, strange but clean."""

def gen_one(slug, theme, stype, idea, elements, labels, output):
    prompt = build_prompt(theme, stype, idea, elements, labels)
    print(f"⏳ {slug}...", end=" ", flush=True)
    body = json.dumps({"model": "Tongyi-MAI/Z-Image-Turbo", "prompt": prompt, "n": 1, "size": "1792x1024"})
    proc = subprocess.run(
        ["curl", "-s", "-X", "POST", "https://api.siliconflow.cn/v1/images/generations",
         "-H", f"Authorization: Bearer {API_KEY}", "-H", "Content-Type: application/json", "-d", body],
        capture_output=True, text=True, timeout=90)
    try:
        data = json.loads(proc.stdout)
        url = data.get("data", [{}])[0].get("url", "")
        if url:
            subprocess.run(["curl", "-s", url, "-o", output], timeout=30)
            sz = os.path.getsize(output)
            print(f"✅ {sz//1024}KB")
            return True
        print(f"❌")
    except: print("❌")
    return False

def main():
    out = os.path.join(os.getcwd(), "dev_docs", "images")
    os.makedirs(out, exist_ok=True)
    for slug, (theme, stype, idea, elements, labels) in SHOTS.items():
        gen_one(slug, theme, stype, idea, elements, labels, os.path.join(out, f"{slug}-cover.png"))
        time.sleep(2)

if __name__ == "__main__":
    main()
