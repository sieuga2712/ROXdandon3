# Khung kỹ thuật Ragnarokdandon

Nguyên tắc: **khung code dựng một lần, mọi con số nằm trong file dữ liệu.** Đổi số, thêm skill, thêm class, thêm cấp đá đều không phải sửa code.

Thiết kế game (class, skill, đá cường hóa): [Ragnarokdandon – Thiết kế game](https://claude.ai/code/artifact/d65f1e71-cac8-4644-ba49-e7400a188570).

---

## 1. Đã chốt

| # | Câu hỏi | Chốt | Hệ quả cho code |
|---|---|---|---|
| 1 | Online hay offline? | **Offline** | Tính hết trong Godot. Logic trận đánh vẫn tách khỏi Node (mục 3). |
| 2 | Đội hình | **3 hàng xếp ngang kiểu King's Raid: đầu, giữa, cuối. Hàng chỉ là chỗ xuất phát** | Sân 1 làn theo trục x (mục 6.1). |
| 3 | Chỉ số | **atk, matk, hp, def, mdef, atsp, crit, crit dmg, kháng CC, mana/s, hút máu, damage_taken** | Danh sách ở mục 5.1. |
| 4 | Skill có lên cấp không? | **Có** | Số của skill để dạng mảng theo cấp. Save lưu cấp từng skill. |
| 5 | Nhân vật/quái có di chuyển không? | **Có**. Tốc chạy và tầm đánh **cố định** theo class/quái | Mục 5.2 và 6. |
| 6 | Bị động có cộng dồn không? | **Có** | `stack_rule` mặc định là `stack` (mục 5.5). |
| 7 | Quái | **Xếp 3 hàng như phe mình. Chỉ đánh thường + skill hồi chiêu, không có chiêu cuối, không có mana** | Quái dùng chung khung đơn vị với nhân vật, chỉ bỏ loại 3 (mục 6.2). |
| 8 | Đá cường hóa | **Tạm dùng chung, chưa chia loại công/thủ. Cấp cường hóa nằm trên món đồ**, đồ tháo ra lắp cho nhân vật khác được | Mục 7. Save lưu kho đồ, mỗi món có id riêng và cấp cường hóa riêng. |
| 9 | Khống chế boss | **Thanh choáng.** Boss miễn choáng thường. Thanh chỉ trừ khi boss đang niệm, và chỉ skill khống chế mới trừ. Phá thanh thì boss ngừng niệm và choáng 1 giây, sau đó thanh bị khóa một lúc rồi đầy lại. Boss niệm xong mà không phá được thì chỉ ăn đòn to, không thua ngay | Mục 6.3. |
| 10 | Nhân vật | **Mỗi class đúng 1 nhân vật.** Muốn nhiều nhân vật thì làm nhiều class | Nhân vật và class dùng chung một id. Số nhân vật = số class. |
| 11 | Trang bị | **Kiểu Ragnarok.** Vũ khí khóa theo loại vũ khí (cung chỉ Cung thủ, kiếm dùng chung Chiến binh và Hiệp sĩ...). Áo và mũ chia 3 nhóm: thiên mdef (kiểu đồ Pháp sư), thiên pdef (kiểu đồ Cung thủ), cân bằng (tuyến đầu). Phụ kiện ai cũng mặc được | Mỗi món đồ gốc có `equip_tag` (ví dụ `sword`, `bow`, `armor_magic`, `armor_light`, `armor_balanced`, `accessory`). Mỗi class có danh sách tag được mặc. |
| 12 | Skill | **Có kho skill chung**, người chơi tự lắp skill cho từng màn | Skill không gắn cứng vào class. Mỗi skill có tag class được dùng (hoặc dùng chung). Nhân vật có ô skill theo loại. |
| 13 | Nội dung ngoài trận chính | **Bỏ kỹ năng đời sống.** Thay bằng phó bản ngày và treo máy nhận nguyên liệu kiểu AFK Arena | Mục 8. |
| 14 | Ô skill mỗi nhân vật | **2 nội tại + 2 hồi chiêu + 1 chiêu cuối** | Mục 4.7. |
| 15 | Cấp skill | **Skill chung tính cấp chung cho cả tài khoản. Skill riêng class tính riêng** (mỗi class 1 nhân vật nên cũng là riêng nhân vật đó) | Save có 2 bảng cấp skill (mục 9). |
| 16 | Đồ có đổi hình nhân vật không? | **Không.** Hình (tóc, mũ, giáp...) là trang trí, chọn ở màn tạo nhân vật. Chỉ vũ khí cầm tay đổi hình theo loại vũ khí | Chỉ số lấy từ đồ, hình lấy từ cấu hình trang trí. BattleView chỉ cần biết loại vũ khí. |
| 17 | Thưởng treo máy | **Tính theo màn cao nhất đã qua** | Mục 8.3. |
| 18 | Ép dùng nhiều đội | **Mỗi màn (và phó bản) có yêu cầu riêng**, để một đội không spam được mãi | Mỗi màn có danh sách `rules` (mục 8.1). |

| 19 | Cường hóa tăng gì | **Mỗi cấp cộng thẳng 5% chỉ số gốc của món đồ đó** (cấp 200 = gấp 11 lần). Tạm cộng cả chỉ số %, cân bằng sau | Mục 7.2. |
| 20 | Đổi đồ mới | **Cho chuyển cấp cường hóa** từ món cũ sang món mới | Mục 7.2. |
| 21 | Bộ skill | **Lưu theo preset**, chọn preset trước khi vào màn. **Preset không chứa đồ**, đồ nằm trên nhân vật | Mục 4.7 và 9. |

Hiện không còn câu nào mở về khung.

---

## 2. Để sau thoải mái

Mấy thứ này nằm trong file dữ liệu, sửa lúc nào cũng được:

- Mọi con số skill: % ATK, hồi chiêu, mana, thời gian hiệu ứng, số theo từng cấp skill.
- Đường cong giá đá 200 cấp, tỉ lệ ghép đá, tỉ lệ thất bại.
- Thêm class, thêm loại đá, thêm quái, thêm màn.

---

## 3. Tổng quan

```
 Dữ liệu (.tres / .csv)            Logic trận đánh (thuần GDScript)            Hình ảnh (scene Godot)
 ───────────────────────           ────────────────────────────────            ──────────────────────
 class, skill, quái, đá  ──nạp──▶  BattleSim: chạy theo tick cố định  ──sự kiện──▶  BattleView
 bảng giá, bảng chỉ số             không biết gì về Node, Sprite, UI              rig nhân vật, rig quái,
                                   đầu vào: đội hình + seed ngẫu nhiên             số sát thương, thanh máu
                                   đầu ra: danh sách sự kiện + kết quả
                                          │
                                          └──▶ BalanceRunner: chạy 1000 trận không có hình, in thống kê
```

- **BattleSim không đụng tới Node.** Nó chỉ nhận dữ liệu, chạy và phát sự kiện (`move`, `attack`, `skill_cast`, `damage`, `heal`, `shield`, `status_add`, `death`, ...).
- **BattleView chỉ nghe sự kiện rồi diễn.** Sự kiện `move` thì phát `Walk` và dời rig tới vị trí mới. Sự kiện `attack` thì phát `Attack`, đợi tín hiệu `OnAttackHit` của rig rồi hiện số sát thương. Rig quái ở [scenes/monsters/](../scenes/monsters/) đã có sẵn tín hiệu này.
- **Seed ngẫu nhiên cố định** thì cùng đầu vào ra cùng kết quả. Nhờ vậy test được và phát lại được.

---

## 4. Skill là dữ liệu

Mỗi skill là một resource `SkillData`. Không viết class GDScript riêng cho từng skill. Tất cả skill nằm trong **một kho chung**. Skill riêng class có tag class, skill chung thì không có tag, class nào cũng lắp được.

### 4.1 Ba loại skill

| Loại | `kind` | Khi nào kích hoạt | Ví dụ |
|---|---|---|---|
| 1. Nội tại | `passive` | Theo `when` (4.2), không cần bấm, không tốn mana | Tăng tốc đánh bất chợt (xác suất mỗi đòn), buff toàn team |
| 2. Hồi chiêu | `cooldown` | Hết hồi chiêu là tự dùng | Mưa tên, Chém xoáy |
| 3. Hồi chiêu + mana | `ultimate` | Hết hồi chiêu **và** đủ mana. Dùng xong trừ mana, bắt đầu hồi chiêu lại | Tên xuyên tim, Thiên thạch |

Loại 3 mặc định tự dùng. Người chơi tắt auto thì chỉ dùng khi bấm tay, và nút chỉ sáng khi đủ cả hai điều kiện.

### 4.2 Nội tại kích hoạt khi nào (`when`)

| `when` | Ý nghĩa | Dùng cho |
|---|---|---|
| `always` | Luôn có hiệu lực từ đầu trận | Bị động buff toàn team (tăng atsp, tăng hp, ...) |
| `on_attack` | Mỗi đòn đánh thường, tung xác suất `chance` | Skill xác suất cũ của 5 class |
| `on_hit_taken` | Mỗi lần bị đánh, tung xác suất `chance` | Để dành, ví dụ phản đòn |
| `on_low_hp` | Một lần khi HP xuống dưới ngưỡng `threshold` | Để dành, ví dụ cứu mạng |

Như vậy mỗi class có thể có nhiều nội tại: một cái `on_attack` (skill xác suất) và một cái `always` (buff toàn team). Cả hai cùng là loại 1.

### 4.3 Các trường

| Trường | Ý nghĩa | Ví dụ |
|---|---|---|
| `id` | mã duy nhất | `archer_arrow_rain` |
| `kind` | `passive` / `cooldown` / `ultimate` | `cooldown` |
| `class_tags` | class được lắp skill này. Rỗng = skill chung, ai cũng lắp được, cấp tính cho cả tài khoản | `["archer"]` |
| `when` | chỉ cho `passive` (4.2) | `on_attack` |
| `chance` | chỉ cho `on_attack` / `on_hit_taken` | `0.15` |
| `cooldown` | giây, cho `cooldown` và `ultimate` | `8.0` |
| `mana_cost` | chỉ cho `ultimate` | `100` |
| `start_cooldown` | hồi chiêu ban đầu khi vào trận, để skill không nổ ngay giây đầu | `3.0` |
| `cast_range` | tầm dùng skill. Mục tiêu xa hơn thì chạy lại gần trước. `0` = không cần tầm | `0` |
| `cast_time` | giây vận chiêu trước khi ra đòn, `0` = ra ngay. Dùng cho chiêu lớn của boss để người chơi kịp phá thanh choáng | `2.5` |
| `break_power` | lượng trừ vào thanh choáng của boss mỗi lần trúng (mục 6.3). **Chỉ skill khống chế mới có**, đánh thường và skill khác để `0` | `30` |
| `target` | bộ chọn mục tiêu (4.4) | `random_enemy` |
| `target_count` | số mục tiêu, `0` = tất cả | `5` |
| `radius` | bán kính, cho bộ chọn theo vùng | `120` |
| `effects` | danh sách hiệu ứng (4.5), chạy theo thứ tự | xem 4.6 |
| `animation` | tên clip cho rig | `Attack` |
| `levels` | mảng số theo cấp skill. Mỗi phần tử ghi đè các số của cấp đó | `[{cooldown: 8, scale: 0.6}, {cooldown: 7.5, scale: 0.7}]` |

### 4.4 Bộ chọn mục tiêu

Vì có di chuyển, các bộ chọn tính theo khoảng cách trên trục x thay vì theo hàng:

`self` · `current_target` · `nearest_enemy` · `random_enemy` · `all_enemies` · `enemies_near_self` (trong `radius` quanh mình) · `enemies_near_target` (trong `radius` quanh mục tiêu) · `highest_hp_enemy` · `lowest_hp_ally` · `all_allies`

Thêm bộ chọn mới là thêm một hàm, không đụng skill cũ.

### 4.5 Hiệu ứng

| Hiệu ứng | Tham số |
|---|---|
| `damage` | `scale` (% atk hoặc matk), `type` (`physical` / `magic`), `hits`, `force_crit` |
| `heal` | `scale`, `basis` (`max_hp` / `atk` / `matk`) |
| `shield` | `scale`, `basis` (`caster_max_hp` / `target_max_hp`), `duration` |
| `modify_stat` | `stat`, `value`, `mode` (`flat` / `percent`), `duration` (`0` = cả trận, dùng cho nội tại `always`) |
| `stun` | `duration` (bị giảm bởi kháng CC) |
| `slow` | `value` (% tốc chạy và atsp), `duration` (bị giảm bởi kháng CC) |
| `taunt` | `duration` (bị giảm bởi kháng CC) |
| `knockback` | `distance` |
| `cleanse` | `count` |
| `undying` | `duration` (HP không xuống dưới 1) |
| `extra_attacks` | `count` |

### 4.6 Các skill trong doc ghép theo 3 loại

Số lấy từ doc thiết kế, **đều là số tạm**. Chỗ doc chưa có số để `?`. Doc chưa có hồi chiêu cho chiêu cuối, nên loại 3 để `? s`.

| Class | Loại | Skill | Kích hoạt | Mục tiêu | Hiệu ứng |
|---|---|---|---|---|---|
| Cung thủ | 1 | Tăng tốc đánh (team) | always | all_allies | `modify_stat` atsp +?% |
| Cung thủ | 1 | Tăng tốc đánh bất chợt | on_attack ? | self | `modify_stat` atsp +?% ?s |
| Cung thủ | 2 | Mưa tên | 8s | random_enemy × 5 | `damage` 60% atk |
| Cung thủ | 3 | Tên xuyên tim | ? s + 100 mana | highest_hp_enemy | `damage` 400% atk, force_crit |
| Chiến binh | 1 | Tăng sát thương (team) | always | all_allies | `modify_stat` atk +?%, matk +?% |
| Chiến binh | 1 | Hút máu, 3 đòn liên tiếp | on_attack ? | self | `modify_stat` lifesteal +?%, `extra_attacks` 2 |
| Chiến binh | 2 | Chém xoáy | 10s | enemies_near_self | `damage` 120% atk, `modify_stat` lifesteal ×2 3s |
| Chiến binh | 3 | Cuồng nộ | ? s + 100 mana | self | `modify_stat` atk +50% 8s (+ theo % máu đã mất) |
| Tu sĩ | 1 | Tăng HP (team) | always | all_allies | `modify_stat` hp +?% |
| Tu sĩ | 1 | Sát thương 2 lần + hồi máu | on_attack ? | current_target, rồi lowest_hp_ally | `damage` ?% matk × 2, `heal` ? |
| Tu sĩ | 2 | Ánh sáng thanh tẩy | 12s | all_allies | `heal` 15% max_hp, `cleanse` 1 |
| Tu sĩ | 3 | Phước lành | ? s + 100 mana | all_allies | `heal` 40% max_hp, `undying` 3s |
| Hiệp sĩ | 1 | Tăng giáp (team) | always | all_allies | `modify_stat` def +?% |
| Hiệp sĩ | 1 | Tạo giáp ảo | on_attack ? | self | `shield` ? |
| Hiệp sĩ | 2 | Khiêu khích | 10s | enemies_near_self + self | `taunt` 4s, `modify_stat` damage_taken −30% 4s |
| Hiệp sĩ | 3 | Thành trì | ? s + 100 mana | all_allies | `shield` 20% caster_max_hp 6s |
| Pháp sư | 1 | Tăng hồi mana (team) | always | all_allies | `modify_stat` mana_regen +?% |
| Pháp sư | 1 | Sát thương AoE | on_attack ? | enemies_near_target | `damage` ?% matk |
| Pháp sư | 2 | Băng giá | 9s | enemies_near_target | `damage` 100% matk, `slow` 30% 3s |
| Pháp sư | 3 | Thiên thạch | ? s + 100 mana | enemies_near_target | `damage` 350% matk, `stun` 2s |

Ghi chú:

- Có di chuyển nên "Băng giá làm chậm" giờ có nghĩa thật: giảm cả tốc chạy lẫn atsp.
- Chiêu cuối giờ cần cả hồi chiêu, nên **hồi chiêu của loại 3 là cái phanh** cho lỗi "chiêu cuối hồi nhanh quá" đã nêu. Dù mana đầy nhanh, chiêu cuối vẫn không ra sớm hơn hồi chiêu.
- Bị động cộng dồn (đã chốt) thì 4 Cung thủ cộng 4 lần atsp. Trần atsp ở mục 5.4 là chỗ chặn chuyện này.
- 20 skill trên là bộ khởi đầu, đều là skill riêng class. Skill chung (ví dụ một chiêu khống chế ai cũng lắp được) thêm sau, chỉ là thêm file.

### 4.7 Ô skill và bộ skill lắp

- Mỗi nhân vật có **5 ô**: 2 nội tại, 2 hồi chiêu, 1 chiêu cuối. Ô nào chỉ nhận skill đúng loại.
- Lắp được skill khi `class_tags` rỗng hoặc chứa class của nhân vật.
- Một skill chung không lắp 2 lần trên cùng một nhân vật. Nhiều nhân vật khác nhau lắp cùng một skill chung thì được.
- Cấp skill khi vào trận: skill chung lấy cấp chung của tài khoản, skill riêng lấy cấp của class đó.
- **Preset**: mỗi preset lưu 4 nhân vật ra trận, hàng của từng người, và 5 ô skill của từng người. Chọn preset trước khi vào màn. Preset **không** chứa đồ.

---

## 5. Chỉ số

### 5.1 Chỉ số gốc (đã chốt)

Có trên class, quái, đá cường hóa, UI và save.

| Mã | Tên | Ghi chú |
|---|---|---|
| `atk` | Công vật lý | |
| `matk` | Công phép | |
| `hp` | Máu tối đa | |
| `def` | Thủ vật lý | |
| `mdef` | Thủ phép | |
| `atsp` | Tốc đánh | số đòn mỗi giây, có trần |
| `crit` | Tỉ lệ chí mạng | 0–1 |
| `crit_dmg` | Sát thương chí mạng | ví dụ 1.5 = 150% |
| `cc_resist` | Kháng CC | giảm thời gian choáng/chậm/khiêu khích: `thời gian × (1 − cc_resist)`, trần đề xuất 0.6 |
| `mana_regen` | Hồi mana mỗi giây | quái không dùng |
| `lifesteal` | Hút máu | % sát thương gây ra được hồi lại |
| `damage_taken` | Hệ số sát thương nhận vào | mặc định 1.0. Khiêu khích −30% thì thành 0.7. Áp sau khi đã trừ def/mdef |

Doc thiết kế còn nhắc "tăng sát thương". Cái này quy về +% atk/matk, không cần thêm chỉ số.

### 5.2 Thuộc tính cố định theo class/quái

Không nâng cấp được, nằm trong dữ liệu class/quái:

`move_speed` (tốc chạy) · `attack_range` (tầm đánh thường) · `mana_per_attack` · `mana_per_hit_taken` · `mana_max`

Mana vào từ 3 nguồn: `mana_regen` mỗi giây, mỗi đòn đánh thường, mỗi lần bị đánh. Quái không có mana nên bỏ qua 3 trường mana.

Quái có thêm `break_max`, `break_lock`, `break_regen`, `is_boss` (mục 6.3). Quái thường để `break_max = 0`.

### 5.3 Công thức sát thương (khung, số chỉnh sau)

```
gốc        = atk hoặc matk × scale của skill
sau thủ    = gốc × K / (K + def hoặc mdef)        (K là hằng số trong dữ liệu)
chí mạng   = × crit_dmg nếu trúng crit
cuối cùng  = sau thủ × damage_taken của bên nhận
hút máu    = cuối cùng × lifesteal của bên đánh
```

Thủ tính theo kiểu chia (`K / (K + def)`) để def càng cao càng ít lợi, không bao giờ chặn hết 100%.

### 5.4 Cách tính

Mỗi nguồn (chỉ số gốc của class, đá cường hóa, nội tại, buff trong trận) đẩy vào một `StatModifier`:

```
StatModifier { stat, value, mode: flat | percent, source_id, stack_rule }
```

Giá trị cuối = `(gốc + tổng flat) × (1 + tổng percent)`, sau đó kẹp vào trần/sàn của chỉ số đó (ví dụ `atsp`, `cc_resist`).

### 5.5 Cộng dồn

`stack_rule` của mỗi modifier:

- `stack` (mặc định, đã chốt): cộng hết.
- `highest`: các modifier cùng `source_id` chỉ lấy cái lớn nhất.

Để `highest` sẵn trong khung, phòng khi chơi thử thấy đội 4 người cùng class mạnh quá.

---

## 6. Trận đánh: tick, di chuyển, đội hình

### 6.1 Sân đấu

- **Sân ngang 1 làn kiểu King's Raid.** Phe mình bên trái, quái bên phải. Logic chỉ dùng tọa độ **x**. Trục y chỉ để BattleView xếp hình so le cho đẹp, sim không tính.
- **3 hàng (đầu, giữa, cuối) chỉ là chỗ xuất phát**, cho cả phe mình lẫn quái. Hàng đầu gần địch nhất. Nhiều đơn vị cùng hàng thì cùng x, khác y hiển thị.
- Sau khi trận bắt đầu, ai cũng chạy về phía mục tiêu tới khi vào tầm `attack_range` thì đứng lại đánh. Không có lùi lại.
- Mục tiêu mặc định của đánh thường: `nearest_enemy`. Bị khiêu khích thì phải đánh kẻ khiêu khích.
- Hệ quả: hàng vẫn có tác dụng ở chỗ ai đứng trước thì bị nhắm trước. Xếp Cung thủ hàng đầu thì Cung thủ ăn đòn trước.
- Không tính va chạm. Đơn vị chồng lên nhau trên trục x được, hình đã so le theo y.

### 6.2 Thứ tự mỗi tick (0.1 giây) cho từng đơn vị

1. Trừ thời gian hiệu ứng, gỡ cái hết hạn. Cộng mana theo `mana_regen`. Trừ hồi chiêu.
2. Choáng thì bỏ qua tới tick sau.
3. **Loại 3** (quái bỏ qua bước này): hết hồi chiêu, đủ mana, đang auto (hoặc người chơi vừa bấm) và mục tiêu trong `cast_range` → dùng.
4. Nếu không, **loại 2**: hết hồi chiêu và mục tiêu trong `cast_range` → dùng.
5. Nếu không, mục tiêu trong `attack_range` và đến lượt đánh theo `atsp` → **đánh thường**. Trong đòn đánh tung xác suất các nội tại `on_attack`.
6. Nếu không, mục tiêu ngoài tầm → **chạy** về phía mục tiêu theo `move_speed` (bị `slow` giảm).
7. Mỗi tick tối đa 1 hành động. Đang vận chiêu (`cast_time`) thì đứng yên tới khi ra đòn. Đơn vị thường dính choáng thì bị ngắt. Boss chỉ bị ngắt khi vỡ thanh choáng (6.3).

Nội tại `always` áp vào lúc vào trận. Nội tại `on_hit_taken` và `on_low_hp` chạy ngay khi sự kiện xảy ra, không chiếm lượt.

Người chơi bấm tay chiêu cuối là một lệnh đưa vào sim (`cast_ultimate(unit_id)`), không gọi thẳng vào hình. Nhờ vậy phát lại trận vẫn đúng.

### 6.3 Thanh choáng của boss

- Chỉ quái có `break_max > 0` mới có thanh (boss, có thể cả quái tinh anh).
- **Boss miễn choáng thường.** Các hiệu ứng khống chế (`stun`, `slow`, `taunt`, `knockback`) đánh vào boss không có tác dụng gì, chỉ trừ thanh.
- **Thanh chỉ trừ khi boss đang niệm** (`cast_time`). Ngoài lúc niệm, khống chế vào boss là phí.
- **Chỉ skill khống chế mới trừ thanh**, theo `break_power` của skill. Đánh thường và skill không khống chế không trừ.
- Thanh về 0 (vỡ): hủy chiêu đang niệm, boss choáng **1 giây**, không bị giảm bởi `cc_resist`. Phát sự kiện `break`, BattleView phát clip `Stun` của rig.
- Sau khi vỡ: thanh bị khóa `break_lock` giây, rồi đầy lại.
- Boss niệm xong mà thanh chưa vỡ: thanh hồi đầy cho lần niệm sau (`break_regen` để dành nếu muốn hồi dần thay vì đầy ngay).

---

## 7. Trang bị, đá cường hóa và tiền tệ

### 7.1 Trang bị

- **4 ô:** vũ khí, áo, mũ, phụ kiện.
- Mỗi món đồ gốc (`data/items/`): `id, slot, equip_tag, chỉ số gốc`.
- `equip_tag` quyết định ai mặc được:

| Ô | `equip_tag` | Ai mặc |
|---|---|---|
| Vũ khí | theo loại: `bow`, `sword`, `staff`, `mace`, ... | class nào có tag đó trong danh sách. Ví dụ `sword`: Chiến binh, Hiệp sĩ. `bow`: Cung thủ |
| Áo, mũ | `armor_magic` (thiên mdef), `armor_light` (thiên def), `armor_balanced` (cân bằng) | Pháp sư, Tu sĩ → `armor_magic`. Cung thủ → `armor_light`. Chiến binh, Hiệp sĩ → `armor_balanced` |
| Phụ kiện | `accessory` | mọi class |

- Bảng class nào mặc tag nào nằm trong dữ liệu class, đổi lúc nào cũng được. Phân nhóm áo cho Tu sĩ ở trên là tạm.
- Lưu ý khi làm class mới: cường hóa theo món chỉ có giá trị khi món đó có từ 2 class trở lên dùng được. Mỗi loại vũ khí nên có ít nhất 2 class.
- Đồ không đổi hình nhân vật. BattleView chỉ đổi sprite vũ khí cầm tay theo loại vũ khí.

### 7.2 Đá cường hóa

- `gem_types.csv`: `id, image, tier (0–4: trắng→vàng)`. **Tạm dùng chung**, chưa chia loại công/thủ. Muốn chia sau thì thêm cột `stat_group`, không đổi khung.
- `enhance_curve.csv`: một dòng mỗi cấp, 200 dòng: `level, gem_tier, gem_count, gold_cost, success_rate, fail_drop`.
- `gem_merge.csv`: `from_tier, to_tier, count_in, gold_cost`.
- **Cấp cường hóa nằm trên món đồ** (đã chốt). Kho đồ lưu từng món: `item_id, base_id, enhance_level`. Nhân vật chỉ lưu "ô nào đang lắp món nào". Tháo đồ ra lắp cho nhân vật khác thì cấp cường hóa đi theo đồ.
- **Cường hóa tăng gì:** chỉ số của món đồ = `chỉ số gốc × (1 + enhance_bonus × cấp)`, với `enhance_bonus = 0.05` (cộng thẳng, không nhân dồn). Cấp 200 = gấp 11 lần đồ gốc.
- Tạm áp cho **mọi** chỉ số của món đồ, kể cả chỉ số % (crit, hút máu, ...). Mỗi chỉ số có cờ `enhance_scales` trong dữ liệu, mặc định bật. Sau này muốn chỉ số % không tăng theo cường hóa thì tắt cờ, không sửa code.
- Trần chỉ số ở mục 5.4 vẫn chặn phía sau. Nên đặt trần cho `crit` (1.0), `lifesteal`, `cc_resist`, `atsp` ngay từ đầu.
- **Chuyển cấp cường hóa:** chuyển từ món cũ sang món mới **cùng ô**. Tốn tiền và có thể mất một phần cấp, cả hai số nằm trong `enhance_transfer.csv`. Món cũ về cấp 0.

### 7.3 Tiền tệ

Một ví duy nhất. Mọi chỗ cộng/trừ tiền đi qua một hàm có ghi nguồn (`reason`), để sau đếm được tiền vào/ra từ đâu khi cân bằng kinh tế.

---

## 8. Màn chơi, phó bản ngày, treo máy

### 8.1 Màn chơi

- Mỗi màn (`data/stages/`): `id, chương, các đợt quái (quái nào, hàng nào), boss nếu có, phần thưởng, rules`.
- **`rules`** là danh sách yêu cầu của màn, để một đội không đánh mãi mọi màn được. Mỗi rule là một mảnh dữ liệu, sim kiểm tra lúc xếp đội và áp lúc vào trận. Ví dụ:

| Rule | Ý nghĩa |
|---|---|
| `ban_class` | cấm một số class |
| `require_class_count` | phải có ít nhất N class thuộc nhóm nào đó (ví dụ ≥ 2 class phép) |
| `ban_row` | cấm xếp người vào một hàng |
| `enemy_immune` | quái miễn sát thương vật lý hoặc phép |
| `enemy_modifier` | quái được cộng chỉ số (ví dụ +200% def) |
| `team_modifier` | đội mình bị trừ chỉ số (ví dụ −50% hồi máu) |
| `max_team_size` | ra trận ít hơn 4 người |
| `time_limit` | hết giờ là thua |

- Thêm rule mới là thêm một hàm kiểm tra, không đổi khung.

### 8.2 Phó bản ngày

- Lịch phó bản theo thứ trong tuần nằm trong dữ liệu. Mỗi ngày một hoặc vài phó bản, mỗi cái có `rules` riêng và phần thưởng nguyên liệu riêng.
- Số lượt mỗi ngày giới hạn. Save lưu ngày reset gần nhất và số lượt đã dùng.

### 8.3 Treo máy

- Thưởng treo máy tính theo **màn cao nhất đã qua**: mỗi màn có `idle_rate` (nguyên liệu/giờ) trong dữ liệu.
- Save lưu mốc thời gian lần nhận cuối. Khi nhận: `thưởng = idle_rate × min(thời gian đã qua, giờ tối đa)`. Giờ tối đa nằm trong dữ liệu.
- Game offline nên chỉnh giờ máy là gian lận được. Dự án cá nhân, chấp nhận, không chặn.

---

## 9. Save

- Một file JSON có `save_version` ngay từ bản đầu tiên.
- Mỗi lần đổi cấu trúc thì thêm một bước nâng cấp `v1 → v2`. Không bao giờ sửa save cũ tại chỗ.
- Chỉ lưu id và cấp, không lưu số đã tính sẵn, để đổi bảng số thì save cũ tự ăn theo số mới. Gồm:
    - Nhân vật (theo class id): đã mở chưa, cấu hình trang trí, 4 ô đồ đang lắp món nào (item id), cờ auto chiêu cuối.
    - Kho đồ: `item_id, base_id, enhance_level`.
    - Cấp skill: bảng skill chung (theo tài khoản) và bảng skill riêng (theo class).
    - Preset: 4 nhân vật, hàng, 5 ô skill mỗi người. Không chứa đồ.
    - Tiến độ: màn cao nhất, màn đã qua.
    - Treo máy: mốc thời gian lần nhận cuối.
    - Phó bản ngày: ngày reset gần nhất, số lượt đã dùng.
    - Ví tiền, kho đá, kho nguyên liệu.

---

## 10. Mô phỏng cân bằng

`BalanceRunner` chạy BattleSim không có hình:

- Đầu vào: danh sách đội hình, màn quái, số trận, seed.
- Đầu ra: tỉ lệ thắng, thời gian trận, sát thương/hồi máu theo class, số lần dùng mỗi skill, thời gian chạy so với thời gian đánh.
- Dùng để trả lời bằng số những câu như "Tu sĩ có mạnh nhất không", "4 Cung thủ có ăn đứt đội đủ class không", "chiêu cuối bao lâu có một lần".

---

## 11. Thư mục dự kiến

```
data/
  classes/        archer.tres, warrior.tres, ...      (chỉ số gốc, thuộc tính 5.2, equip_tag được mặc)
  skills/         archer_arrow_rain.tres, ...         (kho skill chung, có class_tags)
  items/          bow_wood.tres, armor_magic_cloth.tres, ...
  monsters/       slime_green.tres, ...               (chỉ số + thuộc tính 5.2 + scene rig)
  stages/         1_1.tres, ...                       (đợt quái, rules, phần thưởng, idle_rate)
  daily/          schedule.tres
  economy/        gem_types.csv, enhance_curve.csv, gem_merge.csv, enhance_transfer.csv
scripts/
  battle/         battle_sim.gd, unit_state.gd, skill_runner.gd, targeting.gd, effects.gd,
                  stats.gd, movement.gd
  data/           skill_data.gd, class_data.gd, monster_data.gd
  save/           save_service.gd, migrations.gd
  tools/          balance_runner.gd
scenes/
  battle/         battle_view.tscn
  monsters/       (đã có: rig quái + animation)
  character_creation/   (đã có)
```

---

## 12. Thứ tự làm

1. ~~Chốt khung~~ (xong).
2. `stats.gd` + `skill_data.gd` + `effects.gd` + `targeting.gd`, kèm test nhỏ cho từng hiệu ứng.
3. `movement.gd` + `battle_sim.gd`: 5 class đánh slime với số tạm, in log ra console.
4. `balance_runner.gd`, chạy 1000 trận, sửa mấy lỗi cân bằng đã biết.
5. `battle_view.tscn` gắn rig nhân vật và slime vào sự kiện (`Walk` khi chạy, `Attack` khi đánh).
6. Trang bị (4 ô, `equip_tag`) và đá cường hóa bậc 1–2 đọc từ CSV, rồi mới tới 200 cấp.
7. Ô skill và kho skill chung, màn chơi có `rules`.
8. Phó bản ngày và treo máy làm sau cùng.
