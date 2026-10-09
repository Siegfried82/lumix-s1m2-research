/* SPDX-License-Identifier: MIT */
/**
 * @file s1m2_npu_cnn.h
 * @brief CNN Deep Learning Hardware Accelerator and Neural Network model descriptors.
 *
 * Target: Panasonic LUMIX S1M2 (DC-S1M2)
 * SoC: Socionext Milbeaut M20V (Karine / SC2006A / MC8241 / MC8243)
 * Accelerator: Proprietary Convolutional Neural Network (CNN) Engine
 */

#ifndef S1M2_NPU_CNN_H
#define S1M2_NPU_CNN_H

#include "s1m2_types.h"
#include "s1m2_mmap.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 1. CNN Accelerator Hardware Registers                                     */
/* ========================================================================= */

#define S1M2_CNN_BASE_ADDR              S1M2_CNN_CTRL_BASE
#define S1M2_CNN_EXTRA_ADDR             S1M2_CNN_EXTRA_REG_BASE

struct s1m2_cnn_hw_regs {
    reg32_t cnn_ctrl0;          /* +0x00: Engine Enable, Clock Gating, Soft Reset */
    reg32_t cnn_ctrl1;          /* +0x04: Execution Mode, Layer Burst Start */
    reg32_t cnn_status;         /* +0x08: Busy, Complete, Error status flags */
    reg32_t cnn_irq_en;         /* +0x0C: Interrupt enable */
    reg32_t weight_base_low;    /* +0x10: DDR Base address of weight tensors (low 32) */
    reg32_t weight_base_high;   /* +0x14: DDR Base address of weight tensors (high 32) */
    reg32_t feature_in_low;     /* +0x18: Input feature map DDR address (low 32) */
    reg32_t feature_in_high;    /* +0x1C: Input feature map DDR address (high 32) */
    reg32_t feature_out_low;    /* +0x20: Output feature map DDR address (low 32) */
    reg32_t feature_out_high;   /* +0x24: Output feature map DDR address (high 32) */
    reg32_t conv_param_w;       /* +0x28: Kernel width, Stride, Padding */
    reg32_t conv_param_h;       /* +0x2C: Kernel height, Dilation */
    reg32_t activation_cfg;     /* +0x30: ReLU, LeakyReLU, Sigmoid, Quantization scale */
    reg32_t reserved[39];
};

/* ========================================================================= */
/* 2. Neural Network Model Identifiers & Descriptors                         */
/* ========================================================================= */

typedef enum {
    /* 9 Object Detection Networks (~1.375 MiB / 1,441,792 Bytes each) */
    S1M2_CNN_MODEL_NW_1ST = 50, /* Human Body Pose / Skeleton Keypoints */
    S1M2_CNN_MODEL_NW_2ND = 51, /* Human Face & Eye Fine Precision Detection */
    S1M2_CNN_MODEL_NW_3RD = 52, /* Animal / Pet (Cat/Dog) Body & Head Detection */
    S1M2_CNN_MODEL_NW_4TH = 53, /* Bird Full Body & Eye Detection */
    S1M2_CNN_MODEL_NW_5TH = 54, /* Car / Motorsport Racing Vehicle Detection */
    S1M2_CNN_MODEL_NW_6TH = 55, /* Motorcycle / Bicycle & Rider Detection */
    S1M2_CNN_MODEL_NW_7TH = 56, /* Train / Railway Locomotive Detection */
    S1M2_CNN_MODEL_NW_8TH = 57, /* Airplane / Aircraft Detection */
    S1M2_CNN_MODEL_NW_9TH = 58, /* Multi-scale BBox Refinement & Feature Fusion */

    /* Subject High-Dimensional Feature Re-Identification Network (3.00 MiB) */
    S1M2_CNN_MODEL_REID   = 59, /* 3.00 MiB Feature Embedding (59_hm_d_reid.bin) */

    /* AI Deep Learning Auto White Balance Model (1.75 MiB) */
    S1M2_CNN_MODEL_AI_AWB = 60  /* 1.75 MiB Scene Classifier (60_ai_awb_data.bin) */
} s1m2_cnn_model_id_t;

#define S1M2_CNN_DETECTION_MODEL_SIZE   1441792U /* 1.375 MiB */
#define S1M2_CNN_REID_MODEL_SIZE        3145728U /* 3.000 MiB */
#define S1M2_CNN_AWB_MODEL_SIZE         1835008U /* 1.750 MiB */

#define S1M2_CNN_MAGIC                  0x434E4E30U /* "CNN0" */

struct s1m2_cnn_model_header {
    u32 magic;                  /* S1M2_CNN_MAGIC */
    u32 model_id;               /* s1m2_cnn_model_id_t */
    u32 num_layers;             /* Number of fused conv/bn/relu layers */
    u32 input_channels;         /* Input channels (e.g. 3 for RGB) */
    u32 input_width;            /* Network input resolution width */
    u32 input_height;           /* Network input resolution height */
    u32 output_dims;            /* Output dimension (e.g. 512-dim embedding for Re-ID) */
    u32 quant_zero_point;       /* Quantization zero-point */
    u32 quant_scale_q16;        /* Fixed-point scale factor */
    u32 weights_checksum;       /* SHA-256 or CRC32 of tensor payload */
} __packed;

/* ========================================================================= */
/* 3. Subject Tracking & Re-Identification State Machine                     */
/* ========================================================================= */

/**
 * Subject Tracking State Enum
 */
typedef enum {
    S1M2_TRACK_UNACQUIRED = 0,
    S1M2_TRACK_ACQUIRING,       /* Primary detector found subject bounding box */
    S1M2_TRACK_LOCKED,          /* Re-ID feature vector enrolled and locked */
    S1M2_TRACK_COASTING,        /* Brief occlusion: Coasting with Re-ID vector */
    S1M2_TRACK_LOST,            /* Timeout expired: Subject lost */
    S1M2_TRACK_BG_FALLBACK      /* Contrast AF fallback (Causes "Jump to Background") */
} s1m2_track_state_t;

/**
 * Re-ID Bounding Box and Embedding Descriptor
 */
struct s1m2_reid_target {
    u16 bbox_x;
    u16 bbox_y;
    u16 bbox_w;
    u16 bbox_h;
    u16 confidence_score;       /* 0 ~ 1000 */
    u16 class_id;               /* Person, Eye, Animal, Vehicle, etc. */
    float embedding_vector[128];/* Normalized high-dimensional embedding */
};

/**
 * AF Subject Tracking State Machine Tuning Descriptor
 */
struct s1m2_af_tracking_controller {
    s1m2_track_state_t state;
    struct s1m2_reid_target target;
    
    /* Heuristic Counters */
    u32 current_lost_frame_count;
    
    /* Factory Default vs Reverse-Engineered Tuned Thresholds */
    u32 default_lost_timeout;   /* Factory value: 8 ~ 15 frames (~0.2s) - too short! */
    u32 tuned_lost_timeout;     /* Tuned value: 30 ~ 60 frames (~1.0s~2.0s) */
    
    /* Cosine similarity threshold for Re-ID vector matching (0.0 ~ 1.0) */
    float reid_similarity_threshold; /* e.g. 0.72f */
    
    /* Sensitivity for falling back to background contrast AF */
    u32 bg_fallback_sensitivity;/* Lower value prevents sticky background jumping */
};

/* ========================================================================= */
/* 4. AI Auto White Balance (AWB) Descriptor                                 */
/* ========================================================================= */

struct s1m2_ai_awb_result {
    u32 detected_scene_class;   /* Daylight, Cloudy, Shade, Incandescent, Flash, etc. */
    u16 gain_r_q8;              /* Red channel WB multiplier (Q8 format) */
    u16 gain_g_q8;              /* Green channel WB multiplier (Q8 format) */
    u16 gain_b_q8;              /* Blue channel WB multiplier (Q8 format) */
    u16 color_temp_kelvin;      /* Estimated color temperature (e.g. 5600K) */
    u16 tint_duv_q8;            /* Tint adjustment value */
};

#ifdef __cplusplus
}
#endif

#endif /* S1M2_NPU_CNN_H */
