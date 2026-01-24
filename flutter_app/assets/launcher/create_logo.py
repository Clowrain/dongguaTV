#!/usr/bin/env python3
"""
创建类似 Netflix 风格的应用图标 - 艺术感设计
"""
from PIL import Image, ImageDraw, ImageFilter
import os
import math

def create_logo(output_path, size=1024):
    """创建 logo"""
    # 创建图像
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 创建渐变背景 - 从左上到右下的红色渐变
    for y in range(size):
        for x in range(size):
            # 计算从左上到右下的渐变
            progress = (x + y) / (size * 2)
            # Netflix 红色 (229, 9, 20) 到深红色 (180, 0, 10)
            r = int(229 - progress * 49)
            g = int(9 - progress * 9)
            b = int(20 - progress * 10)
            img.putpixel((x, y), (r, g, b, 255))

    # 添加圆角矩形遮罩
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = int(size * 0.12)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], corner_radius, fill=255)

    # 应用遮罩
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)

    draw = ImageDraw.Draw(result)

    # 绘制字母 E - 带倾斜和艺术感
    letter_width = int(size * 0.38)
    letter_height = int(size * 0.50)

    # E 的中心位置
    center_x = size // 2
    center_y = size // 2

    # 倾斜角度（约 10 度）
    skew_angle = math.radians(10)

    # 计算倾斜后的坐标
    def skew_point(x, y, center_x, center_y, angle):
        """对点进行倾斜变换"""
        # 相对于中心的坐标
        rel_x = x - center_x
        rel_y = y - center_y
        # 应用倾斜
        new_x = rel_x + rel_y * math.tan(angle)
        new_y = rel_y
        # 转回绝对坐标
        return int(new_x + center_x), int(new_y + center_y)

    # E 的基础位置 - 向右偏移以补偿倾斜效果
    # 倾斜后字母的视觉中心会偏左，所以需要向右补偿
    skew_compensation = int(letter_height * math.tan(skew_angle) * 0.8)  # 向右补偿

    e_left = center_x - letter_width // 2 + skew_compensation
    e_top = center_y - letter_height // 2
    e_right = center_x + letter_width // 2 + skew_compensation
    e_bottom = center_y + letter_height // 2

    # 线条宽度
    line_width = int(size * 0.10)

    # 创建一个更大的画布用于绘制倾斜的字母
    letter_canvas = Image.new('RGBA', (size * 2, size * 2), (0, 0, 0, 0))
    letter_draw = ImageDraw.Draw(letter_canvas)

    offset = size // 2  # 偏移量，使字母在大画布中心

    # 绘制带圆角的横线函数
    def draw_rounded_rect(draw, left, top, right, bottom, radius, fill):
        """绘制圆角矩形"""
        # 主矩形
        draw.rectangle([left + radius, top, right - radius, bottom], fill=fill)
        draw.rectangle([left, top + radius, right, bottom - radius], fill=fill)
        # 四个角的圆
        draw.ellipse([left, top, left + 2*radius, top + 2*radius], fill=fill)
        draw.ellipse([right - 2*radius, top, right, top + 2*radius], fill=fill)
        draw.ellipse([left, bottom - 2*radius, left + 2*radius, bottom], fill=fill)
        draw.ellipse([right - 2*radius, bottom - 2*radius, right, bottom], fill=fill)

    corner_r = int(line_width * 0.4)  # 圆角半径

    # 绘制左侧竖线（带圆角）
    draw_rounded_rect(letter_draw,
                     e_left + offset, e_top + offset,
                     e_left + line_width + offset, e_bottom + offset,
                     corner_r, 'white')

    # 绘制顶部横线（带圆角）
    draw_rounded_rect(letter_draw,
                     e_left + offset, e_top + offset,
                     e_right + offset, e_top + line_width + offset,
                     corner_r, 'white')

    # 绘制中间横线（稍短，带圆角）
    e_middle = (e_top + e_bottom) // 2
    middle_length = int(letter_width * 0.85)
    draw_rounded_rect(letter_draw,
                     e_left + offset, e_middle - line_width // 2 + offset,
                     e_left + middle_length + offset, e_middle + line_width // 2 + offset,
                     corner_r, 'white')

    # 绘制底部横线（带圆角）
    draw_rounded_rect(letter_draw,
                     e_left + offset, e_bottom - line_width + offset,
                     e_right + offset, e_bottom + offset,
                     corner_r, 'white')

    # 应用倾斜变换
    letter_canvas = letter_canvas.transform(
        letter_canvas.size,
        Image.AFFINE,
        (1, math.tan(skew_angle), -offset * math.tan(skew_angle),
         0, 1, 0),
        resample=Image.BICUBIC
    )

    # 裁剪回原始大小
    letter_mask = letter_canvas.crop((offset, offset, offset + size, offset + size))

    # 创建增强的阴影 - 多层阴影增加深度
    shadow_layers = []
    shadow_offsets = [
        (int(size * 0.020), 80),   # 第一层，较远较淡
        (int(size * 0.012), 100),  # 第二层，中等
        (int(size * 0.006), 120),  # 第三层，较近较深
    ]

    for offset_dist, opacity in shadow_offsets:
        shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow)

        # 将字母遮罩应用为阴影
        for y in range(size):
            for x in range(size):
                pixel = letter_mask.getpixel((x, y))
                if pixel[3] > 0:
                    new_x = min(size - 1, x + offset_dist)
                    new_y = min(size - 1, y + offset_dist)
                    shadow.putpixel((new_x, new_y), (0, 0, 0, opacity))

        # 模糊阴影
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=size * 0.010))
        shadow_layers.append(shadow)

    # 按顺序合成所有阴影层（从远到近）
    for shadow in shadow_layers:
        result = Image.alpha_composite(result, shadow)

    # 应用字母到结果，添加渐变和高光
    for y in range(size):
        for x in range(size):
            pixel = letter_mask.getpixel((x, y))
            if pixel[3] > 0:
                # 计算位置相关的亮度
                # 从左上到右下的渐变
                pos_progress = (x + y) / (size * 2)
                # 从上到下的渐变
                vertical_progress = y / size

                # 组合渐变效果
                brightness = int(255 - vertical_progress * 30 - pos_progress * 15)
                brightness = max(220, min(255, brightness))

                # 添加高光区域（左上部分更亮）
                distance_from_top_left = math.sqrt((x - size * 0.3) ** 2 + (y - size * 0.3) ** 2)
                if distance_from_top_left < size * 0.2:
                    highlight = int((1 - distance_from_top_left / (size * 0.2)) * 20)
                    brightness = min(255, brightness + highlight)

                result.putpixel((x, y), (brightness, brightness, brightness, 255))

    # 添加边缘高光 - 让左上边缘更亮
    for y in range(size):
        for x in range(size):
            pixel = result.getpixel((x, y))
            if pixel[0] > 200:  # 白色字母区域
                # 检查左侧和上方是否是边缘
                is_edge_left = x > 0 and result.getpixel((x - 1, y))[0] < 200
                is_edge_top = y > 0 and result.getpixel((x, y - 1))[0] < 200

                if is_edge_left or is_edge_top:
                    # 左上边缘加亮
                    result.putpixel((x, y), (255, 255, 255, 255))

                # 检查右侧和下方是否是边缘（暗化）
                is_edge_right = x < size - 1 and result.getpixel((x + 1, y))[0] < 200
                is_edge_bottom = y < size - 1 and result.getpixel((x, y + 1))[0] < 200

                if is_edge_right or is_edge_bottom:
                    darken = 25
                    result.putpixel((x, y), (
                        max(0, pixel[0] - darken),
                        max(0, pixel[1] - darken),
                        max(0, pixel[2] - darken),
                        255
                    ))

    # 添加整体光泽效果
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for y in range(size // 2):
        for x in range(size // 2):
            distance = math.sqrt((x - size * 0.25) ** 2 + (y - size * 0.25) ** 2)
            max_distance = size * 0.35
            if distance < max_distance:
                alpha = int((1 - distance / max_distance) ** 2 * 40)
                overlay.putpixel((x, y), (255, 255, 255, alpha))

    result = Image.alpha_composite(result, overlay)

    # 在右下方添加 "视界" 文字 - 倾斜且艺术化
    try:
        # 尝试加载中文字体
        import platform
        system = platform.system()

        font_size = int(size * 0.12)  # 增大字体大小
        font = None

        # 尝试不同系统的中文字体 - 优先粗体
        font_paths = [
            "/System/Library/Fonts/PingFang.ttc",  # macOS
            "/System/Library/Fonts/STHeiti Medium.ttc",  # macOS 中黑
            "/System/Library/Fonts/Hiragino Sans GB.ttc",  # macOS
            "C:/Windows/Fonts/msyhbd.ttc",  # Windows 微软雅黑粗体
            "C:/Windows/Fonts/msyh.ttc",  # Windows 微软雅黑
            "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf",  # Linux
        ]

        from PIL import ImageFont
        for font_path in font_paths:
            try:
                font = ImageFont.truetype(font_path, font_size)
                break
            except:
                continue

        if font is None:
            font = ImageFont.load_default()

        # 创建临时画布用于绘制倾斜文字
        text = "视界"
        temp_canvas = Image.new('RGBA', (size * 2, size * 2), (0, 0, 0, 0))
        temp_draw = ImageDraw.Draw(temp_canvas)

        # 获取文字边界框
        bbox = temp_draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]

        # 文字基础位置（在临时画布中心）
        temp_offset = size // 2
        base_x = int(size * 1.28)  # 向右移动更多
        base_y = int(size * 1.13)  # 向上调整

        # 绘制多层阴影创建深度效果
        shadow_layers = [
            (4, 4, (0, 0, 0, 100)),  # 最远层
            (3, 3, (0, 0, 0, 120)),  # 中层
            (2, 2, (0, 0, 0, 140)),  # 近层
        ]

        for offset_x, offset_y, color in shadow_layers:
            temp_draw.text(
                (base_x + offset_x, base_y + offset_y),
                text,
                font=font,
                fill=color
            )

        # 绘制主文字 - 使用渐变效果
        # 先绘制基础白色文字
        temp_draw.text(
            (base_x, base_y),
            text,
            font=font,
            fill=(255, 255, 255, 255)
        )

        # 应用倾斜变换（与 E 相同的角度）
        temp_canvas = temp_canvas.transform(
            temp_canvas.size,
            Image.AFFINE,
            (1, math.tan(skew_angle), -temp_offset * math.tan(skew_angle),
             0, 1, 0),
            resample=Image.BICUBIC
        )

        # 裁剪回原始大小并合成
        text_layer = temp_canvas.crop((temp_offset, temp_offset, temp_offset + size, temp_offset + size))

        # 为文字添加渐变效果（从上到下稍微变暗）
        for y in range(size):
            for x in range(size):
                pixel = text_layer.getpixel((x, y))
                if pixel[3] > 0:  # 如果有内容
                    # 计算垂直渐变
                    progress = y / size
                    brightness = int(255 - progress * 25)
                    brightness = max(220, min(255, brightness))

                    # 保持原有透明度
                    alpha = pixel[3]
                    text_layer.putpixel((x, y), (brightness, brightness, brightness, alpha))

        # 合成文字层到结果
        result = Image.alpha_composite(result, text_layer)

        print(f"Added artistic text '视界' successfully")
    except Exception as e:
        print(f"Could not add text: {e}")
        import traceback
        traceback.print_exc()

    # 保存图像
    result.save(output_path, 'PNG')
    print(f"Logo created: {output_path} ({size}x{size})")

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # 创建主图标（用于启动图标）
    create_logo(os.path.join(script_dir, 'icon.png'), 1024)

    # 创建启动屏图标（稍小一些）
    create_logo(os.path.join(script_dir, 'splash.png'), 768)

    print("All logos created successfully!")
