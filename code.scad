// --- UFO型コーヒードリッパー：モールド生成プログラム (吊り下げコア方式) ---

/* [表示設定] */
// 表示モードの切り替え
view_mode = 4; // [0:並べて出力 (本体と台座), 1:組み立てプレビュー, 2:モールド：Part 1 雌型, 3:モールド：Part 2 雄型, 4:モールド断面プレビュー]

// 円の滑らかさ
$fn = 120; // [30:Low, 60:Medium, 120:High, 200:Extra Fine]

/* [ドリッパー基本サイズ] */
// ドリッパーの全体角度（度）
dripper_angle = 80;       // [30:120]
// 底の穴の直径 (mm)
bottom_hole_d = 28;       // [10:60]
// 上部の内径 (mm)
top_d = 110;              // [50:150]
// 壁の基本厚さ (mm)
wall_thickness = 6;       // [2:15]
// 外側に広がる段差の幅 (mm)
groove_depth = 1.5;       // [0:5]

/* [リブ・スパイラル設定] */
// リブ（溝）の本数
rib_count = 18;           // [0:40]
// リブの凹みの深さ (mm)
rib_depth = 2.2;          
// リブの凹みの幅 (mm)
rib_width = 4.2;          
// スパイラルのひねり角度（度）
spiral_twist = 60;        // [-180:180]

/* [台座（ベースリング）設定] */
// 台座の外径 (mm)
ring_outer_d = 100;       
// 台座の穴の下部直径 (mm)
ring_inner_bottom_d = 60; 
// 台座の厚み (mm)
ring_thickness = 5;       
// プリント用クリアランス (mm)
clearance = 0.2;          

/* [モールド（型）設定] */
// 型の壁の厚み (mm)
mold_wall = 15; 

// --- 計算用変数（Customizerには表示されません） ---
side_angle = dripper_angle / 2;
total_h = (top_d - bottom_hole_d) / (2 * tan(side_angle));
bottom_r = bottom_hole_d / 2;
top_r = top_d / 2;
outer_bottom_r = bottom_r + (wall_thickness / cos(side_angle));
ring_inner_bottom_r = ring_inner_bottom_d / 2;
radius_at_shelf1 = ring_inner_bottom_r - groove_depth;
shelf_z = (radius_at_shelf1 - outer_bottom_r) / tan(side_angle);
tier2_h = ring_thickness; 
radius_at_shelf2 = ring_inner_bottom_r + (tier2_h * tan(side_angle));
tier3_z = shelf_z + tier2_h;
tier3_h = total_h - tier3_z;
new_outer_top_r = (radius_at_shelf2 + groove_depth) + (tier3_h * tan(side_angle));
ring_inner_top_r = ring_inner_bottom_r + (ring_thickness * tan(side_angle));
mold_outer_r = new_outer_top_r + mold_wall; 

// ==========================================
// パーツモジュール群
// ==========================================

module dripper_outer_solid() {
    union() {
        cylinder(h = shelf_z, r1 = outer_bottom_r, r2 = radius_at_shelf1);
        translate([0, 0, shelf_z])
        cylinder(h = tier2_h, r1 = radius_at_shelf1 + groove_depth, r2 = radius_at_shelf2);
        translate([0, 0, tier3_z])
        cylinder(h = tier3_h, r1 = radius_at_shelf2 + groove_depth, r2 = new_outer_top_r);
    }
}

module dripper_inner_void() {
    translate([0, 0, -1])
    linear_extrude(height = total_h + 2, twist = -spiral_twist, scale = top_r/bottom_r, slices=100)
    union() {
        circle(r = bottom_r); 
        for(i = [0 : rib_count - 1]) {
            rotate([0, 0, i * (360 / rib_count)])
            translate([bottom_r, 0, 0])
            scale([rib_depth, rib_width/2, 1])
            circle(r = 1, $fn=30);
        }
    }
}

module dripper_body() {
    difference() {
        dripper_outer_solid();
        dripper_inner_void();
        translate([0, 0, total_h]) cylinder(h=10, r=new_outer_top_r + 20);
        translate([0, 0, -10]) cylinder(h=10, r=new_outer_top_r + 20);
    }
}

module base_ring() {
    difference() {
        cylinder(h = ring_thickness, d = ring_outer_d);
        translate([0, 0, -1])
        cylinder(h = ring_thickness + 2, r1 = ring_inner_bottom_r + clearance, r2 = ring_inner_top_r + clearance);
    }
}

// --- Part 1: モールド雌型（外側のカップ＋底面） ---
module mold_outer() {
    difference() {
        translate([0, 0, -10]) cylinder(h = total_h + 10, r = mold_outer_r);
        translate([0, 0, 0]) dripper_outer_solid();
        translate([0, 0, total_h]) cylinder(h=20, r=mold_outer_r + 10);
        for(a = [0 : 90 : 270]) {
            rotate([0, 0, a]) 
            translate([mold_outer_r - 7, 0, total_h - 10]) 
            cylinder(h = 10.2, r = 4.3, $fn=30);
        }
    }
}

// --- Part 2: モールド雄型（フタ ＋ 吊り下げコア） ---
module mold_inner() {
    difference() {
        union() {
            translate([0, 0, total_h]) cylinder(h = 12, r = mold_outer_r);
            intersection() {
                dripper_inner_void();
                cylinder(h = total_h, r = mold_outer_r);
            }
            for(a = [0 : 90 : 270]) {
                rotate([0, 0, a]) 
                translate([mold_outer_r - 7, 0, total_h - 10]) 
                cylinder(h = 10, r = 4.0, $fn=30);
            }
        }
        rim_mid_r = new_outer_top_r - (wall_thickness / 2);
        translate([rim_mid_r, 0, total_h - 1])
        cylinder(h = 15, r1 = 4, r2 = 9, $fn=30);
        for(a = [90, 180, 270]) {
            rotate([0, 0, a])
            translate([rim_mid_r, 0, total_h - 1])
            cylinder(h = 15, r = 2.5, $fn=30);
        }
    }
}

// ==========================================
// 表示モードの切り替え
// ==========================================
if (view_mode == 0) {
    color("Khaki") dripper_body();
    color("DarkKhaki") translate([new_outer_top_r + ring_outer_d/2 + 10, 0, 0]) base_ring();
} 
else if (view_mode == 1) {
    color("Khaki") translate([0, 0, -shelf_z]) dripper_body();
    color("DarkKhaki") base_ring();
} 
else if (view_mode == 2) {
    color("SkyBlue") mold_outer();
} 
else if (view_mode == 3) {
    color("LightGreen") mold_inner();
} 
else if (view_mode == 4) {
    difference() {
        union() {
            color("SkyBlue", 0.4) mold_outer();
            color("LightGreen", 0.7) mold_inner();
        }
        translate([0, -mold_outer_r - 5, -20]) 
        cube([(mold_outer_r + 5) * 2, (mold_outer_r + 5) * 2, total_h + 40]);
    }
    color("Red") dripper_body();
}
