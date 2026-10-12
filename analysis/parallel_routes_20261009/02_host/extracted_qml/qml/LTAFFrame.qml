import QtQuick 2.0
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Rectangle {
    id: root
    color: "transparent"

    //Text {
    //    id: mode_label
    //    x: 10
    //    y: 10
    //    color: "white"
    //}
    property int mode: afmode_init
    property int mode_pscope_bk: afmode_init
    property bool center_keep: false
    property int center_x: 200
    property int center_y: 200
    property int center_width: 80
    property int center_height: 80
    // 合焦AF枠の最大行列数
    readonly property int afdisp_x_max: getAFDispSplitMaxNumX()
    readonly property int afdisp_y_max: getAFDispSplitMaxNumY()
    // カスタムマルチの最大行列数
    readonly property int cmulti_x_max: getCMultiSplitMaxNumX()
    readonly property int cmulti_y_max: getCMultiSplitMaxNumY()
    // マルチの中心位置、サイズ
    property int f225_pos_x: 5
    property int f225_pos_y: 5
    property int f225_length: 5
    property int f225_length_old: 5
    // 追尾の中心位置、サイズ
    property int chase_detect_x: 300
    property int chase_detect_y: 300
    property int chase_detect_width: 80
    property int chase_detect_height: 80
    //property int mf_pos_x: -1
    //property int mf_pos_y: -1
    property int mf_x0: -1
    property int mf_y0: -1
    property int mf_X0: -1
    property int mf_Y0: -1
    property bool pinpoint_drag_flg: false
    readonly property bool zone_outer_flg: {
        if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315)
            true
        else
            false
    }
    property bool dispPDAF: false  // PDAF合焦枠表示かどうか
    // センサ種類
    readonly property int sensorType_Full: 0
    readonly property int sensorType_MFTS: 1
    property int sensorType: sensorType_MFTS
    // レンズ種類
    readonly property int lensType_UNKNOWN: -1
    readonly property int lensType_FF: 0
    readonly property int lensType_APS_C: 1
    readonly property int lensType_MFTS: 2
    property int lensType: lensType_FF
    // カスタムマルチの選択枠
    property var custom_frame: []
    // 合焦中のAF枠
    property var focus_frame: []
    // 合焦中のPDAF枠
    property var focus_pdaf: []

    readonly property int afmode_init:              0
    readonly property int afmode_pointone:          1
    readonly property int afmode_point225:          2
    readonly property int afmode_point225s:         3
    readonly property int afmode_point225_af:       4
    readonly property int afmode_point225s_af:      5
    readonly property int afmode_point225f:         6
    readonly property int afmode_point225sf:        7
    readonly property int afmode_point225f_af:      8
    readonly property int afmode_point225sf_af:     9
    readonly property int afmode_face:              10
    readonly property int afmode_face_eye:          11
    readonly property int afmode_face_af:           12
    readonly property int afmode_face_225:          13
    readonly property int afmode_face_225_af:       14
    readonly property int afmode_face_225f:         15
    readonly property int afmode_face_225f_af:      16
    readonly property int afmode_chase:             17
    readonly property int afmode_chase_af:          18
    readonly property int afmode_pinpoint:          19
    readonly property int afmode_pinpointf:         20
    readonly property int afmode_pinpointz:         21
    readonly property int afmode_pinpointp:         22
    readonly property int afmode_custom:            23
    readonly property int afmode_customs:           24
    readonly property int afmode_custom_af:         25
    readonly property int afmode_customs_af:        26
    readonly property int afmode_customf:           27
    readonly property int afmode_customsf:          28
    readonly property int afmode_customf_af:        29
    readonly property int afmode_customsf_af:       30
    readonly property int afmode_mf:                31
    readonly property int afmode_mff:               32
    readonly property int afmode_mfz:               33
    readonly property int afmode_mfp:               34
    readonly property int afmode_pscope:            35
    readonly property int afmode_pscope_z:          36
    readonly property int afmode_pscope_p:          37
    // ivc >> start >> No.3 -> nakhuong
    //readonly property int afmode_num:               28
    readonly property int afmode_pointone_aux:      38
    readonly property int afmode_focusselect:       39
    //readonly property int afmode_num:               40
    // ivc << end << No.3 -> nakhuong
    readonly property int afmode_customo:           40
    readonly property int afmode_customo_af:        41
    readonly property int afmode_customof:          42
    readonly property int afmode_customof_af:       43
    readonly property int afmode_fullarea:          44
    readonly property int afmode_fullarea_af:       45
    readonly property int afmode_fullareaf:         46
    readonly property int afmode_fullareaf_af:      47
    readonly property int afmode_lvmag_z:           48  // 動画LV拡大 Zoom
    readonly property int afmode_lvmag_p:           49  // 動画LV拡大 PinP
    readonly property int afmode_num:               50
    property variant afmode:
    [
        //'init' :
        {
            'value': afmode_init, 'name': qsTr("表示なし"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pointone' :
        {
            'value': afmode_pointone, 'name': qsTr("1点"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': true,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225' :
        {
            'value': afmode_point225, 'name': qsTr("225点マルチ"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225s' :
        {
            'value': afmode_point225s, 'name': qsTr("225点マルチ四角"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225_af' :
        {
            'value': afmode_point225_af, 'name': qsTr("225点マルチAFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225s_af' :
        {
            'value': afmode_point225s_af, 'name': qsTr("225点マルチ四角AFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225f' :
        {
            'value': afmode_point225f, 'name': qsTr("225点マルチ枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': true, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225sf' :
        {
            'value': afmode_point225sf, 'name': qsTr("225点マルチ四角枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': true, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225f_af' :
        {
            'value': afmode_point225f_af, 'name': qsTr("225点マルチ枠AFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': true,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'point225sf_af' :
        {
            'value': afmode_point225sf_af, 'name': qsTr("225点マルチ四角枠AFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': true,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face'     :
        {
            'value': afmode_face, 'name': qsTr("顔"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': true,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face_eye'     :
        {
            'value': afmode_face_eye, 'name': qsTr("瞳検出中"),
            'center_blue': true, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face_af'     :
        {
            'value': afmode_face_af, 'name': qsTr("顔AFON"),
            'center_blue': true, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': true,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face_225' :
        {
            'value': afmode_face_225, 'name': qsTr("顔225点マルチ"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face_225_af' :
        {
            'value': afmode_face_225_af, 'name': qsTr("顔225点マルチAFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face_225f' :
        {
            'value': afmode_face_225f, 'name': qsTr("顔225点マルチ枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': true, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'face_225f_af' :
        {
            'value': afmode_face_225f_af, 'name': qsTr("顔225点マルチ枠AFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': true,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'chase'   :
        {
            'value': afmode_chase, 'name': qsTr("追尾"),
            'center_blue': true, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': true, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'chasing'   :
        {
            'value': afmode_chase_af, 'name': qsTr("追尾中"),
            'center_blue': true, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': true,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pinpoint' :
        {
            'value': afmode_pinpoint, 'name': qsTr("ピンポイント"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pinpointf' :
        {
            'value': afmode_pinpointf, 'name': qsTr("ピンポイント枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': true,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pinpointz' :
        {
            'value': afmode_pinpointz, 'name': qsTr("ピンポイント拡大ズーム"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': true, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pinpointp' :
        {
            'value': afmode_pinpointp, 'name': qsTr("ピンポイント拡大Pinp"),
            'center_blue': false, 'center_blue_s': false, 'center_white': true,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'custom'   :
        {
            'value': afmode_custom, 'name': qsTr("カスタムマルチ"),
            'center_blue': true, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': true, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customs'   :
        {
            'value': afmode_customs, 'name': qsTr("カスタムマルチ四角"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': true, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'custom_af'   :
        {
            'value': afmode_custom_af, 'name': qsTr("カスタムマルチAF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': true, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customs_af'   :
        {
            'value': afmode_customs_af, 'name': qsTr("カスタムマルチ四角AF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': true, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customf'   :
        {
            'value': afmode_customf, 'name': qsTr("カスタムマルチ枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': true,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customsf'   :
        {
            'value': afmode_customsf, 'name': qsTr("カスタムマルチ四角枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': true,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customf_af'   :
        {
            'value': afmode_customf_af, 'name': qsTr("カスタムマルチ枠AF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': true,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customsf_af'   :
        {
            'value': afmode_customsf_af, 'name': qsTr("カスタムマルチ四角枠AF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': true,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'mf' :
        {
            'value': afmode_mf, 'name': qsTr("MF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': true,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'mff' :
        {
            'value': afmode_mff, 'name': qsTr("MF枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': true,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': true,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'mfz' :
        {
            'value': afmode_mfz, 'name': qsTr("MF拡大ズーム"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': true, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'mfp' :
        {
            'value': afmode_mfp, 'name': qsTr("MF拡大Pinp"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pscope' :
        {
            'value': afmode_pscope, 'name': qsTr("ポイントスコープ"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pscope_z' :
        {
            'value': afmode_pscope_z, 'name': qsTr("ポイントスコープズーム"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': true,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': true,
            'frame_outer': false, 'frame_outerf': false
        },
        //'pscope_p' :
        {
            'value': afmode_pscope_p, 'name': qsTr("ポイントスコープPinp"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': true,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        // ivc >> start >> No.3 -> nakhuong
        //'pointone_aux' :
        {
            'value': afmode_pointone_aux, 'name': qsTr("1点+補助"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': true,
            'frame_one_aux': true,
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        // ivc << end << No.3 -> nakhuong
        //'focusselect' :
        {
            'value': afmode_focusselect, 'name': qsTr("フォーカスセレクト"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'customo'   :
        {
            'value': afmode_customo, 'name': qsTr("カスタムマルチ外枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': true, 'frame_outerf': false
        },
        //'customo_af'   :
        {
            'value': afmode_customo_af, 'name': qsTr("カスタムマルチ外枠AF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': true, 'frame_outerf': false
        },
        //'customof'   :
        {
            'value': afmode_customof, 'name': qsTr("カスタムマルチ外枠枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': true
        },
        //'customof_af'   :
        {
            'value': afmode_customof_af, 'name': qsTr("カスタムマルチ外枠枠AF"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': true
        },
        //'fullarea' :
        {
            'value': afmode_fullarea, 'name': qsTr("フルエリア"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'fullarea_af' :
        {
            'value': afmode_fullarea_af, 'name': qsTr("フルエリアAFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': true, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'fullareaf' :
        {
            'value': afmode_fullareaf, 'name': qsTr("フルエリア枠"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': true, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'fullareaf_af' :
        {
            'value': afmode_fullareaf_af, 'name': qsTr("フルエリア枠AFON"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': true, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'lvmag_z' :
        {
            'value': afmode_lvmag_z, 'name': qsTr("動画LV拡大ズーム"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': true, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
        //'lvmag_p' :
        {
            'value': afmode_lvmag_p, 'name': qsTr("動画LV拡大Pinp"),
            'center_blue': false, 'center_blue_s': false, 'center_white': false,
            'frame_one': false,
            // ivc >> start >> No.3 -> nakhuong
            'frame_one_aux': false,
            // ivc << end << No.3 -> nakhuong
            'frame_225': false, 'frame_225f': false, 'frame_225s': false,
            'frame_face': false,
            'frame_chase': false, 'frame_chase_af': false,
            'frame_custom': false, 'frame_customf': false,
            'frame_pinpoint': false, 'frame_drag': false,
            'frame_small': false,
            'frame_outer': false, 'frame_outerf': false
        },
    ];

    readonly property int mfzoom_mode_unknown: -1
    readonly property int mfzoom_mode_normal : 0
    readonly property int mfzoom_mode_pinp   : 1
    readonly property int mfzoom_mode_move   : 2
    property int mfzoom_mode: mfzoom_mode_unknown

    signal pinpoint_af_zoom_started()
    signal mf_zoom_started()

    signal dispAfOff()

    function mfAssistModeSetting(arg) {
        LTSubFunction.console_debug.out("mfAssistModeSetting arg="+arg+" mode="+mode)
        mfzoom_mode = arg

        // 動画LV拡大
        if(deviceAdapter.lvMagEnable &&
//           (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
            deviceAdapter.isExpMovieMode() &&
            (deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG) &&
            (deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Zoom)) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_lvmag_z")
            if(mode !== afmode_lvmag_z)
            {
                root.mf_X0 = -1
                root.mf_Y0 = -1
            }
            changeMode(afmode_lvmag_z)
        }
        else if(deviceAdapter.lvMagEnable &&
//                (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                deviceAdapter.isExpMovieMode() &&
                (deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG) &&
                (deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Pinp)) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_lvmag_p")
            changeMode(afmode_lvmag_p)
        }
        //AF pinpoint
        else if((mfzoom_mode == mfzoom_mode_pinp)
                && ((mode == afmode_pinpoint)
                    || (mode == afmode_pinpointf)
                    || (mode == afmode_pinpointz) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_pinpointp")
            changeMode(afmode_pinpointp)
        }
        else if((mfzoom_mode == mfzoom_mode_normal)
                && ( (mode == afmode_pinpoint)
                    || (mode == afmode_pinpointf)
                    || (mode == afmode_pinpointp) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_pinpointz")
            //root.mf_pos_x = -1
            //root.mf_pos_y = -1
            changeMode(afmode_pinpointz)
        }
        else if((mfzoom_mode == mfzoom_mode_move)
                && ( (mode == afmode_pinpoint)
                    || (mode == afmode_pinpointz)
                    || (mode == afmode_pinpointp) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_pinpointf")
            changeMode(afmode_pinpointf)
        }
        //else if((mfzoom_mode == mfzoom_mode_unknown) && ( (mode == afmode_pinpointp) || (mode == afmode_pinpointz) || (mode == afmode_pinpointf) ) ) {
        else if((mfzoom_mode == mfzoom_mode_unknown)
                && ( (mode == afmode_pinpointp)
                    || (mode == afmode_pinpointf)
                    || (mode == afmode_pinpointz) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_pinpoint")
            changeMode(afmode_pinpoint)
        }
        //MF assist
        else if((mfzoom_mode == mfzoom_mode_pinp)
                && ( (mode == afmode_mf)
                    || (mode == afmode_mff)
                    || (mode == afmode_mfz) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_mfp")
            if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
                //アシストモード：PinP        2
                changeMode(afmode_mfp)
            }
        }
        else if((mfzoom_mode == mfzoom_mode_normal)
                && ( (mode == afmode_mf)
                    || (mode == afmode_mff)
                    || (mode == afmode_mfp) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_mfz")
            //root.mf_pos_x = -1
            //root.mf_pos_y = -1
            root.mf_X0 = -1
            root.mf_Y0 = -1
            if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                changeMode(afmode_mfz)
            }
        }
        else if((mfzoom_mode == mfzoom_mode_move)
                && ( (mode == afmode_mf)
                    || (mode == afmode_mfz)
                    || (mode == afmode_mfp) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_mff")
            if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Move) {
                changeMode(afmode_mff)
            }
        }
        //else if((mfzoom_mode == mfzoom_mode_unknown) && ( (mode == afmode_mff) || (mode == afmode_mfz) || (mode == afmode_mfp) ) ) {
        else if((mfzoom_mode == mfzoom_mode_unknown)
                && ( (mode == afmode_mfz)
                    || (mode == afmode_mff)
                    || (mode == afmode_mfp) ) ) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_mf")
            changeMode(afmode_mf)
        }
        // AFAE lock
        else if((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_unknown)) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afae unknown")
            dispFrame()
        }
        else if((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_pinp)) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afae pinp")
            center_rect.visible = false
            pinpointZoom.visible = false
            afframe225.visible = false
            afframePDAF.visible = false
        }
        else if((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_normal)) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afae normal")
            center_rect.visible = false
            pinpointZoom.visible = true
            root.mf_X0 = -1
            root.mf_Y0 = -1
            afframe225.visible = false
            afframePDAF.visible = false
        }
        //AF point scope
        else if(deviceAdapter.assistType == LT.Utilities.AFFrameAssistType_AFPS) {
            LTSubFunction.console_debug.out("mfAssistModeSetting afmode_pscope mode = " + deviceAdapter.mfa_mode)
            if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                changeMode(afmode_pscope_z)
            } else if (deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
                changeMode(afmode_pscope_p)
            }
        }
    }

    function mfAssistZoomSetting(cx,cy,aw,ah,minx,maxx,miny,maxy) {
        LTSubFunction.console_debug.out("mfAssistZoomSetting cx="+cx+" cy="+cy+" aw="+aw+" ah="+ah)
        LTSubFunction.console_debug.out("mfAssistZoomSetting minx="+minx+" miny="+miny+" maxx="+maxx+" maxy="+maxy)

//        pinpointFrame.x      = parseInt(((cx - parseInt(aw/2)) * pinpointZoom.width)  / 1000)
//        pinpointFrame.y      = parseInt(((cy - parseInt(ah/2)) * pinpointZoom.height) / 1000)
//        pinpointFrame.width  = parseInt((aw * pinpointZoom.width)  / 1000)
//        pinpointFrame.height = parseInt((ah * pinpointZoom.height) / 1000)

        pinpointFrame.x      = (cx - aw/2) * pinpointZoom.width  / 1000
        pinpointFrame.y      = (cy - ah/2) * pinpointZoom.height / 1000
        pinpointFrame.width  = aw * pinpointZoom.width / 1000
        pinpointFrame.height = ah * pinpointZoom.height / 1000

        pinpointFrame.minX = minx
        pinpointFrame.maxX = maxx
        pinpointFrame.minY = miny
        pinpointFrame.maxY = maxy

        //ドラッグエリアの情報更新がウインドウサイズ変更時以外にも行うようにしておく
        ppMsArea.drag.minimumX = pinpointFrame.minDragX()
        ppMsArea.drag.maximumX = pinpointFrame.maxDragX()
        ppMsArea.drag.minimumY = pinpointFrame.minDragY()
        ppMsArea.drag.maximumY = pinpointFrame.maxDragY()
    }

    function mfAssistDragFrameSetting() {
        var aw = deviceAdapter.af_pinpoin_frame_area_width();
        var ah = deviceAdapter.af_pinpoin_frame_area_height();

        var minx = deviceAdapter.af_pinpoin_frame_upper_leftX();
        var maxx = deviceAdapter.af_pinpoin_frame_lower_rightX();
        var miny = deviceAdapter.af_pinpoin_frame_upper_leftY();
        var maxy = deviceAdapter.af_pinpoin_frame_lower_rightY();

        frame_drag.dragFrameSetting(aw, ah, minx, maxx, miny, maxy)
    }

    function setMeteringSpot(arg) {
        LTSubFunction.console_debug.out("setMeteringSpot arg =" + arg)
        var frames = afmode
        if(arg == true) {
            afmode[afmode_pointone].center_blue         = true
            afmode[afmode_pointone].center_white        = false
            // ivc >> start >> No.3 -> nakhuong
            afmode[afmode_pointone_aux].center_blue     = true
            afmode[afmode_pointone_aux].center_white    = false
            // ivc << end << No.3 -> nakhuong
            afmode[afmode_point225].center_blue         = true
            afmode[afmode_point225s].center_blue        = true
            afmode[afmode_point225s].center_white       = false
            afmode[afmode_point225_af].center_blue      = false
            afmode[afmode_point225_af].center_blue_s    = true
            afmode[afmode_point225_af].center_white     = false
            afmode[afmode_point225s_af].center_blue     = true
            afmode[afmode_point225f].center_blue        = true
            afmode[afmode_point225sf].center_blue       = true
            afmode[afmode_point225sf].center_white      = false
            afmode[afmode_point225f_af].center_blue     = false
            afmode[afmode_point225f_af].center_blue_s   = true
            afmode[afmode_point225f_af].center_white    = false
            afmode[afmode_point225sf_af].center_blue    = true
            afmode[afmode_face].center_blue             = true
            afmode[afmode_face_eye].center_blue         = true
            afmode[afmode_face_af].center_blue          = true
            afmode[afmode_face_225].center_blue         = true
            afmode[afmode_face_225_af].center_blue      = false
            afmode[afmode_face_225_af].center_blue_s    = true
            afmode[afmode_face_225_af].center_white     = false
            afmode[afmode_face_225f].center_blue        = true
            afmode[afmode_face_225f_af].center_blue     = false
            afmode[afmode_face_225f_af].center_blue_s   = true
            afmode[afmode_face_225f_af].center_white    = false
            afmode[afmode_chase].center_blue            = true
            afmode[afmode_chase_af].center_blue         = true
            afmode[afmode_pinpoint].center_blue_s       = true
            afmode[afmode_pinpoint].center_white        = false
            afmode[afmode_pinpointf].center_blue_s      = true
            afmode[afmode_pinpointf].center_white       = false
            afmode[afmode_pinpointp].center_blue_s      = true
            afmode[afmode_pinpointp].center_white       = false
            afmode[afmode_pinpointz].center_blue_s      = true
            afmode[afmode_pinpointz].center_white       = false
            afmode[afmode_custom].center_blue           = true
            afmode[afmode_customs].center_blue          = true
            afmode[afmode_customs].center_white         = false
            afmode[afmode_custom_af].center_blue        = true
            afmode[afmode_customs_af].center_blue       = true
            afmode[afmode_customf].center_blue          = true
            afmode[afmode_customsf].center_blue         = true
            afmode[afmode_customsf].center_white        = false
            afmode[afmode_customf_af].center_blue       = true
            afmode[afmode_customsf_af].center_blue      = true
            afmode[afmode_mf].center_blue               = true
            afmode[afmode_mff].center_blue              = true
            afmode[afmode_mfz].center_blue              = false         // 全画面時十字を消す
            afmode[afmode_mfp].center_blue              = true
            afmode[afmode_focusselect].center_blue      = true
            afmode[afmode_customo].center_blue          = true
            afmode[afmode_customo_af].center_blue       = true
            afmode[afmode_customof].center_blue         = true
            afmode[afmode_customof_af].center_blue      = true
            afmode[afmode_fullarea].center_blue         = true
            afmode[afmode_fullarea_af].center_blue      = true
            afmode[afmode_fullareaf].center_blue        = true
            afmode[afmode_fullareaf_af].center_blue     = true
        } else {
            afmode[afmode_pointone].center_blue         = false
            afmode[afmode_pointone].center_white        = false
            // ivc >> start >> No.3 -> nakhuong
            afmode[afmode_pointone_aux].center_blue     = false
            afmode[afmode_pointone_aux].center_white    = false
            // ivc << end << No.3 -> nakhuong
            afmode[afmode_point225].center_blue         = false
            afmode[afmode_point225s].center_blue        = false
            afmode[afmode_point225s].center_white       = true
            afmode[afmode_point225_af].center_blue      = false
            afmode[afmode_point225_af].center_blue_s    = false
            afmode[afmode_point225_af].center_white     = true
            afmode[afmode_point225s_af].center_blue     = false
            afmode[afmode_point225f].center_blue        = false
            afmode[afmode_point225sf].center_blue       = false
            afmode[afmode_point225sf].center_white      = true
            afmode[afmode_point225f_af].center_blue     = false
            afmode[afmode_point225f_af].center_blue_s   = false
            afmode[afmode_point225f_af].center_white    = true
            afmode[afmode_point225sf_af].center_blue    = false
            afmode[afmode_face].center_blue             = false
            afmode[afmode_face_eye].center_blue         = false
            afmode[afmode_face_af].center_blue          = false
            afmode[afmode_face_225].center_blue         = false
            afmode[afmode_face_225_af].center_blue      = false
            afmode[afmode_face_225_af].center_blue_s    = false
            afmode[afmode_face_225_af].center_white     = true
            afmode[afmode_face_225f].center_blue        = false
            afmode[afmode_face_225f_af].center_blue     = false
            afmode[afmode_face_225f_af].center_blue_s   = false
            afmode[afmode_face_225f_af].center_white    = true
            afmode[afmode_chase].center_blue            = false
            afmode[afmode_chase_af].center_blue         = false
            afmode[afmode_pinpoint].center_blue_s       = false
            afmode[afmode_pinpoint].center_white        = true
            afmode[afmode_pinpointf].center_blue_s      = false
            afmode[afmode_pinpointf].center_white       = true
            afmode[afmode_pinpointz].center_blue_s      = false
            afmode[afmode_pinpointz].center_white       = true
            afmode[afmode_pinpointp].center_blue_s      = false
            afmode[afmode_pinpointp].center_white       = true
            afmode[afmode_custom].center_blue           = false
            afmode[afmode_customs].center_blue          = false
            afmode[afmode_customs].center_white         = true
            afmode[afmode_custom_af].center_blue        = false
            afmode[afmode_customs_af].center_blue       = false
            afmode[afmode_customf].center_blue          = false
            afmode[afmode_customsf].center_blue         = false
            afmode[afmode_customsf].center_white        = true
            afmode[afmode_customf_af].center_blue       = false
            afmode[afmode_customsf_af].center_blue      = false
            afmode[afmode_mf].center_blue               = false
            afmode[afmode_mff].center_blue              = false
            afmode[afmode_mfz].center_blue              = false
            afmode[afmode_mfp].center_blue              = false
            afmode[afmode_focusselect].center_blue      = false
            afmode[afmode_customo].center_blue          = false
            afmode[afmode_customo_af].center_blue       = false
            afmode[afmode_customof].center_blue         = false
            afmode[afmode_customof_af].center_blue      = false
            afmode[afmode_fullarea].center_blue         = false
            afmode[afmode_fullarea_af].center_blue      = false
            afmode[afmode_fullareaf].center_blue        = false
            afmode[afmode_fullareaf_af].center_blue     = false
        }
        afmode = frames
        dispFrame()
    }

    readonly property int afcv_1p_cen_no_disp:          0
    readonly property int afcv_1p_cen_unfoc_prog:       1
    readonly property int afcv_1p_cen_big_green:        2
    readonly property int afcv_1p_cen_big_red:          3
    readonly property int afcv_1p_cen_white:            4
    readonly property int afcv_1p_cen_other:            5
    readonly property int afcv_1p_cen_green:            6
    readonly property int afcv_1p_cen_red:              7
    readonly property int afcv_1p_cen_default:          8
    function changeValuePointOneCenter(t, x, y, w, h, mini) {
        LTSubFunction.console_debug.out("changeValuePointOneCenter t="+t+" x="+x+" y="+y+" w="+w+" h="+h+" mini="+mini)
        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦
        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空

        switch(t) {
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        case afcv_1p_cen_no_disp:
            //center_plus.visible = false
            center_rect.visible = false
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // １点白表示
        case afcv_1p_cen_unfoc_prog:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mode == afmode_face_af) {
                if(mini){
                    center_rect.changeMode(center_rect.afmode_sq_minimum_yellow)  // 最小表示
                }else{
                    center_rect.changeMode(center_rect.afmode_sq_normal_yellow)  // 通常
                }
                center_aux_rect.changeMode(center_rect.afmode_sq_normal_yellow)
            } else {
                if(mini){
                    center_rect.changeMode(center_rect.afmode_sq_minimum_white)  // 最小表示
                }else{
                    center_rect.changeMode(center_rect.afmode_sq_normal_white)  // 通常
                }
                center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            }
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が「AF枠表示：緑枠(大)」の場合、緑で表示。
        // 枠（大）表示
        case afcv_1p_cen_big_green:
            //center_plus.visible = false
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_green)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_green)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            root.center_x = 500; root.center_y = 500; root.center_width = 600; root.center_height = 600;
            break
        //合焦枠情報の０番目の値が「AF枠表示：赤枠(大)」の場合、赤で表示。
        // 枠（大）表示
        case afcv_1p_cen_big_red:
            //center_plus.visible = false
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_red)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_red)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_red)
            root.center_x = 500; root.center_y = 500; root.center_width = 600; root.center_height = 600;
            break;
        //合焦枠情報の０番目の値が「AF枠表示：白枠(大)」の場合、白で表示。
        // 枠（大）表示
        case afcv_1p_cen_white:
            //center_plus.visible = false
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_white)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_white)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = 500; root.center_y = 500; root.center_width = 600; root.center_height = 600;
            break;
        //・上記条件に当てはまらない場合
        // １点表示
        //AF情報ステータスが、「非合焦」、「ローライトAF中」の場合、白で表示
        case afcv_1p_cen_other:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_white)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_white)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
        case afcv_1p_cen_green:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_green)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_green)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break;
        //合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
        case afcv_1p_cen_red:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_red)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_red)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_red)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が上記以外の場合、白で表示。
        case afcv_1p_cen_default:
        default:
            LTSubFunction.console_debug.out("changeValuePointOneCenter mfzoom_mode="+mfzoom_mode)
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_white)  // 最小表示
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_white)  // 通常
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        }
    }

    // ivc >> start >> No.3 -> nakhuong
    function changeValuePointOneAuxCenter(t, x, y, w, h, mini) {
        LTSubFunction.console_debug.out("changeValuePointOneAuxCenter t="+t+" x="+x+" y="+y+" w="+w+" h="+h+" mini="+mini)
        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦
        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空

        switch(t) {
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        case afcv_1p_cen_no_disp:
            center_rect.visible = false
            center_aux_rect.visible = false
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // １点白表示
        case afcv_1p_cen_unfoc_prog:
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mode == afmode_face_af) {
                if(mini){
                    center_rect.changeMode(center_rect.afmode_sq_minimum_yellow)
                }else{
                    center_rect.changeMode(center_rect.afmode_sq_normal_yellow)
                }
                center_aux_rect.changeMode(center_rect.afmode_sq_normal_yellow)
            } else {
                if(mini){
                    center_rect.changeMode(center_rect.afmode_sq_minimum_white)
                }else{
                    center_rect.changeMode(center_rect.afmode_sq_normal_white)
                }
                center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            }
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が「AF枠表示：緑枠(大)」の場合、緑で表示。
        // 枠（大）表示
        case afcv_1p_cen_big_green:
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_green)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_green)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            root.center_x = 500; root.center_y = 500; root.center_width = 600; root.center_height = 600;
            break
        //合焦枠情報の０番目の値が「AF枠表示：赤枠(大)」の場合、赤で表示。
        // 枠（大）表示
        case afcv_1p_cen_big_red:
            //center_plus.visible = false
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_red)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_red)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_red)
            root.center_x = 500; root.center_y = 500; root.center_width = 600; root.center_height = 600;
            break;
        //合焦枠情報の０番目の値が「AF枠表示：白枠(大)」の場合、白で表示。
        // 枠（大）表示
        case afcv_1p_cen_white:
            //center_plus.visible = false
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_white)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_white)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = 500; root.center_y = 500; root.center_width = 600; root.center_height = 600;
            break;
        //・上記条件に当てはまらない場合
        // １点表示
        //AF情報ステータスが、「非合焦」、「ローライトAF中」の場合、白で表示
        case afcv_1p_cen_other:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_white)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_white)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
        case afcv_1p_cen_green:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_green)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_green)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break;
        //合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
        case afcv_1p_cen_red:
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_red)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_red)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_red)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が上記以外の場合、白で表示。
        case afcv_1p_cen_default:
        default:
            LTSubFunction.console_debug.out("changeValuePointOneAuxCenter mfzoom_mode="+mfzoom_mode)
            //center_plus.visible = true
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                center_rect.visible = true
                center_aux_rect.visible = true
            }
            if(mini){
                center_rect.changeMode(center_rect.afmode_sq_minimum_white)
            }else{
                center_rect.changeMode(center_rect.afmode_sq_normal_white)
            }
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        }
    }
    // ivc << end << No.3 -> nakhuong

    readonly property int afcv_225p_no_disp:            0
    readonly property int afcv_225p_1p_on:              1
    readonly property int afcv_225p_unfoc_prog:         2
    readonly property int afcv_225p_big_green:          3
    readonly property int afcv_225p_big_red:            4
    readonly property int afcv_225p_white:              5
    readonly property int afcv_225p_other:              6
    readonly property int afcv_225p_default:            7
    function changeValuePoint225(t, x, y, w, h, mi, ms, dn) {
        LTSubFunction.console_debug.out("changeValuePoint225 t="+t+" x="+x+" y="+y+" w="+w+" h="+h+" mi="+mi+" ms="+ms+" dn="+dn)
        var i = 0
        switch(t) {
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        case afcv_225p_no_disp:
            //afframe225.visible = false
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            break;
        //・簡易１点AF状態が、「簡易1点AF ON」の場合
        // １点白表示
        case afcv_225p_1p_on:
            //afframe225.visible = false
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            break;
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // テザーアプリのAF枠表示がONの場合はAF枠表示
        case afcv_225p_unfoc_prog:
            //if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
            if(dispPDAF){
                afframe225.visible = false
                if(!afframePDAF.visible) {
                    afframePDAF.visible = true
                }
            }else{
                afframePDAF.visible = false
                if(!afframe225.visible) {
                    afframe225.visible = true
                }
            }
            //}
            changeValue225(mi, ms, dn)
            resetValueFocus()
            dispValue225()
            //afframe225.f225_focus_timer_Triggered()
            break;
        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        // 枠（大）表示
        case afcv_225p_big_green:
        case afcv_225p_big_red:
        case afcv_225p_white:
            //afframe225.visible = false
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            break;
        //・上記条件に当てはまらない場合
        // 225点表示
        case afcv_225p_other:
            LTSubFunction.console_debug.out("changeValuePoint225 case other")
            if(dispPDAF){
                afframe225.visible = false
                if(!afframePDAF.visible) {
                    afframePDAF.visible = true
                }
            }else{
                afframePDAF.visible = false
                if(!afframe225.visible) {
                    afframe225.visible = true
                }
            }
            //changeValue225(0,0,0)
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            resetValueFocus()
            if(dn != 0) {
                if(dispPDAF){
                    var disp_max = getFrame779SplitNumX()*getFrame779SplitNumY()
                    for(i = 0 ; i < disp_max; i ++) {
                        var di = deviceAdapter.af_pdaf_display_DispInfo(i);
                        //LTSubFunction.console_debug.out("i="+i+" di="+di)
                        if(di == LT.Utilities.AfInfoDispFrame_Green) {
                            changeValueFocus(i)
                        }
                    }
                }else{
                    var disp_max = afdisp_x_max * afdisp_y_max
                    for(i = 0 ; i < disp_max; i ++) {
                        var di = deviceAdapter.af_display_DispInfo(i);
                        //LTSubFunction.console_debug.out("i="+i+" di="+di)
                        if(di == LT.Utilities.AfInfoDispFrame_Green) {
                            changeValueFocus(i)
                        }
                    }
                }
                dispValue225Focus()
                //f225_focus_timer_start()
            } else {
                dispValue225Focus()
                switch(afframe.mode) {
                case afframe.afmode_face://
                case afframe.afmode_face_eye://
                case afframe.afmode_face_af://
                case afframe.afmode_face_225://
                case afframe.afmode_face_225f://
                case afframe.afmode_face_225_af://
                case afframe.afmode_face_225f_af://
                case afframe.afmode_chase://
                case afframe.afmode_chase_af://
                    //afframe225.visible = false
                    afframe225.disp_clear()
                    afframePDAF.disp_clear()
                    break;
                }

                afframe225.f225_focus_timer_Triggered()
            }
            break;
        case afcv_225p_default:
        default:
            LTSubFunction.console_debug.out("changeValuePoint225 case default afaeStartFlg="+afaeStartFlg+" mfzoom_mode="+mfzoom_mode)
            if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
//            if(!afframe225.visible) {
                if(dispPDAF){
//console.debug("afframePDAF.visible true3")
                    afframe225.visible = false
                    afframePDAF.visible = true
                }else{
                    afframe225.visible = true
                    afframePDAF.visible = false
                }
            } else {
                afframe225.visible = false
                center_plus.visible = false
                afframePDAF.visible = false
            }

            //}
            changeValue225(mi, ms, dn)
            resetValueFocus()
            dispValue225Focus()
            dispValue225()
            if(dn != 0) {
                if(dispPDAF){
// console.debug("dispPDAF dn != 0")
                    var disp_max = getFrame779SplitNumX()*getFrame779SplitNumY()
                    for(i = 0 ; i < disp_max; i ++) {
                        var di = deviceAdapter.af_pdaf_display_DispInfo(i);
                        if(di == LT.Utilities.AfInfoDispFrame_Green) {
                            changeValueFocus(i)
                        }
                    }
                }else{
// console.debug("dispPDAF dn == 0")
                    var disp_max = afdisp_x_max * afdisp_y_max
                    for(i = 0 ; i < disp_max; i ++) {
                        var di = deviceAdapter.af_display_DispInfo(i);
                        //LTSubFunction.console_debug.out("i="+i+" di="+di)
                        if(di == LT.Utilities.AfInfoDispFrame_Green) {
                            changeValueFocus(i)
                        }
                    }
                }

                dispValue225Focus()
                //f225_focus_timer_start()
            } else {
                switch(afframe.mode) {
                case afframe.afmode_face://
                case afframe.afmode_face_eye://
                case afframe.afmode_face_af://
                case afframe.afmode_face_225://
                case afframe.afmode_face_225f://
                case afframe.afmode_face_225_af://
                case afframe.afmode_face_225f_af://
                case afframe.afmode_chase://
                case afframe.afmode_chase_af://
                    //afframe225.visible = false
                    afframe225.disp_clear()
                    break;
                }

                afframe225.f225_focus_timer_Triggered()
            }
            break;
        }
    }

    //function changeValueCenter_x(arg) { root.center_x = arg }
    //function changeValueCenter_y(arg) { root.center_y = arg }
    //function changeValueCenter_w(arg) { root.center_width = arg }
    //function changeValueCenter_h(arg) { root.center_height = arg }
    //function movePositionCenter(arg1, arg2) { root.center_x += arg1; root.center_y += arg2;}
    //function movePositionCenter_x(arg) { root.center_x += arg }
    //function movePositionCenter_y(arg) { root.center_y += arg }
    //function addValueCenter_w(arg) { root.center_width += arg }
    //function addValueCenter_h(arg) { root.center_height += arg }

    // マルチ、カスタムマルチAF枠の中心設定
    function changeValue225(arg1, arg2, arg3){
//       LTSubFunction.console_debug.out("changeValue225 arg1="+arg1+" arg2="+arg2+" arg3="+arg3)
//       console.debug("マルチ、カスタムマルチAF枠の中心設定arg1="+arg1+" arg2="+arg2+" arg3="+arg3)
        root.f225_length_old = root.f225_length
        root.f225_pos_x = (arg1 % root.cmulti_x_max)
        root.f225_pos_y = parseInt(arg1 / root.cmulti_x_max)
        root.f225_length = arg2

        afframePDAF_timer.running = false
        afframePDAF_timer.sizeChangeMode = false
        afframePDAF_timer.running = true
    }
    // マルチAF枠を表示
    function dispValue225() {
        afframe225.afmode_point225f_disp()
    }

    // AF合焦枠をリセット
    function resetValueFocus(){
        focus_frame = []
        focus_pdaf = []
    }
    // AF合焦枠を追加
    function changeValueFocus(index){
        var x = 0
        var y = 0
        if(dispPDAF){
            x = (index % getFrame779SplitNumX())
            y = parseInt(index / getFrame779SplitNumX())
            focus_pdaf.push(new Array(x,y))
        }else{
            x = (index % root.afdisp_x_max)
            y = parseInt(index / root.afdisp_x_max)
            focus_frame.push(new Array(x,y))
        }
    }
    // AF合焦枠を表示
    function dispValue225Focus() {
        if(dispPDAF){
            afframePDAF.pdaf_frame_focus_disp()
        }else{
            afframe225.afmode_point225f_focus_disp()
        }
    }
    function pdaf_frames_update()
    {
//console.debug(" レンズが変わればPDAF枠を更新する disp_update ! ", root.width, " ", root.height)
        afframePDAF.disp_update()
    }

    onWidthChanged:{
        if(root.width >= 1 && root.height >= 1){
//console.debug(" onWidthChanged call disp_update ! ", root.width, " ", root.height)
            //LV画面のサイズ変えられたときに更新処理を毎回呼ばないようにする
            afframePDAF_timer.running = false
            afframePDAF_timer.sizeChangeMode = true
            afframePDAF_timer.running = true
//            afframePDAF.disp_update()
        }
    }
    onHeightChanged:{
        if(root.width >= 1 && root.height >= 1){
//console.debug(" onHeightChanged call disp_update ! ", root.width, " ", root.height)
            //LV画面のサイズ変えられたときに更新処理を毎回呼ばないようにする
            afframePDAF_timer.running = false
            afframePDAF_timer.sizeChangeMode = true
            afframePDAF_timer.running = true
//            afframePDAF.disp_update()
        }
    }

    // カスタムマルチAF枠設定
    function changeValueCustom(t, ci, ms, dn) {
        LTSubFunction.console_debug.out("changeValueCustom t="+t+" ci="+ci+" ms="+ms+" dn="+dn)
        var i = 0
        switch(t) {
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        case afcv_225p_no_disp:
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            break;
        //・簡易１点AF状態が、「簡易1点AF ON」の場合
        // １点白表示
        case afcv_225p_1p_on:
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            break;
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // テザーアプリのAF枠表示がONの場合はAF枠表示
        case afcv_225p_unfoc_prog:
            if(dispPDAF){
                afframe225.visible = false
                if(!afframePDAF.visible) {
                    afframePDAF.visible = true
                }
            }else{
                afframePDAF.visible = false
                if(!afframe225.visible) {
                    afframe225.visible = true
                }
            }
            resetValueCustom()
            var frame_max = cmulti_x_max * cmulti_y_max
            for(i = 0 ; i < frame_max; i ++) {
                var af_cmulti_table_data = deviceAdapter.af_cmulti_table_data(i);
                if(af_cmulti_table_data) {
                    afframe.changeValueCustomMulti(i)
                }
            }
            dispValueCustom()
            resetValueFocus()
            break;
        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        // 枠（大）表示
        case afcv_225p_big_green:
        case afcv_225p_big_red:
        case afcv_225p_white:
            //afframe225.visible = false
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            break;
        //・上記条件に当てはまらない場合
        // 225点表示
        case afcv_225p_other:
        case afcv_225p_default:
        default:
            LTSubFunction.console_debug.out("changeValuePoint225 case default")
            if(dispPDAF){
//console.debug("afframePDAF.visible true5")
                afframe225.visible = false
                afframePDAF.visible = true
            }else{
                afframe225.visible = true
                afframePDAF.visible = false
            }

            resetValueCustom()
            var frame_max = cmulti_x_max * cmulti_y_max
            for(i = 0 ; i < frame_max; i ++) {
                af_cmulti_table_data = deviceAdapter.af_cmulti_table_data(i);
                if(af_cmulti_table_data) {
                    changeValueCustomMulti(i)
                }
            }
            dispValueCustom()
            resetValueFocus()
            if(dn != 0) {
                if(dispPDAF){
                    var disp_max = getFrame779SplitNumX()*getFrame779SplitNumY()
                    for(i = 0 ; i < disp_max; i ++) {
                        var di = deviceAdapter.af_pdaf_display_DispInfo(i);
                        if(di == LT.Utilities.AfInfoDispFrame_Green) {
                            changeValueFocus(i)
                        }
                    }
                }else{
                    var disp_max = afdisp_x_max * afdisp_y_max
                    for(i = 0 ; i < disp_max; i ++) {
                        var di = deviceAdapter.af_display_DispInfo(i);
                        if(di == LT.Utilities.AfInfoDispFrame_Green) {
                            changeValueFocus(i)
                        }
                    }
                }
                dispValue225Focus()
            }
            changeValue225(ci, ms, dn)
            afmode_point225f_center_disp()
            break;
        }
    }

    // カスタムマルチ選択枠をリセット
    function resetValueCustom(){
        custom_frame = []
        dispValueCustom()
    }
    // カスタムマルチ選択枠を追加
    function changeValueCustomMulti(index){
        var x = (index % root.cmulti_x_max)
        var y = parseInt(index / root.cmulti_x_max)
        custom_frame.push(new Array(x,y))
    }
    // カスタムマルチ選択枠を表示
    function dispValueCustom(){
        if(root.zone_outer_flg) {
            zone_outer.afmode_custom_disp()
        } else {
            afframe225.afmode_customf_disp()
        }
    }
    //function f225_focus_timer_start() {f225_focus_timer.running = true}

    function changeValueFaceDetect(index, status, s, f, v,x, y, w, h) {
        LTSubFunction.console_debug.out("changeValueFaceDetect index=" + index + " status=" + status + " s=" + s + " v=" + v + " f=" + f + " x=" + x + " y=" + y + " w=" + w + " h=" + h)
        face_rect.changeValue(index, status, s, f, v, x, y, w, h)
    }
    //function changeValueFaceDetect_x(arg) { root.face_detect_x = arg }
    //function changeValueFaceDetect_y(arg) { root.face_detect_y = arg }
    //function changeValueFaceDetect_w(arg) { root.face_detect_width = arg }
    //function changeValueFaceDetect_h(arg) { root.face_detect_height = arg }
    //function movePositionFaceDetect(arg1, arg2) { root.face_detect_x += arg1; root.face_detect_y += arg2;}
    //function movePositionFaceDetect_x(arg) { root.face_detect_x += arg }
    //function movePositionFaceDetect_y(arg) { root.face_detect_y += arg }
    //function addValueFaceDetect_w(arg) { root.face_detect_width += arg }
    //function addValueFaceDetect_h(arg) { root.face_detect_height += arg }

    readonly property int afcv_chase_detect_no_disp:            0
    readonly property int afcv_chase_detect_unfoc_prog:         1
    readonly property int afcv_chase_detect_green:              2
    readonly property int afcv_chase_detect_red:                3
    readonly property int afcv_chase_detect_yellow:             4
    readonly property int afcv_chase_detect_other:              5
    readonly property int afcv_chase_detect_default:            6
    function changeValueChaseDetect(t, x, y, w, h) {
        LTSubFunction.console_debug.out("changeValueChaseDetect t="+t+" x="+x+" y="+y+" w="+w+" h="+h)

        if (afaeStartFlg && mfzoom_mode != mfzoom_mode_unknown) {
            //MF Assit case
            chase_detect_rect.visible = false
            return
        }

        switch(t) {
        case afcv_chase_detect_unfoc_prog:
        case afcv_chase_detect_yellow:
            chase_detect_rect.visible = true
            chase_detect_rect.changeMode(center_rect.afmode_sq_chase_yellow)
            root.chase_detect_x = x; root.chase_detect_y = y; root.chase_detect_width = w; root.chase_detect_height = h;
            root.center_x = x; root.center_y = y;
            break;
        case afcv_chase_detect_green:
            chase_detect_rect.visible = true
            chase_detect_rect.changeMode(center_rect.afmode_sq_chase_green)
            root.chase_detect_x = x; root.chase_detect_y = y; root.chase_detect_width = w; root.chase_detect_height = h;
            root.center_x = x; root.center_y = y;
            break;
        case afcv_chase_detect_red:
            chase_detect_rect.visible = true
            chase_detect_rect.changeMode(center_rect.afmode_sq_chase_red)
            root.chase_detect_x = x; root.chase_detect_y = y; root.chase_detect_width = w; root.chase_detect_height = h;
            root.center_x = x; root.center_y = y;
            break;
        case afcv_chase_detect_other:
            if (afaeStartFlg) {
                chase_detect_rect.visible = false
            } else {
                chase_detect_rect.visible = true
            }

            chase_detect_rect.changeMode(center_rect.afmode_sq_chase_white)
            root.chase_detect_x = x; root.chase_detect_y = y; root.chase_detect_width = parseInt(1000/7); root.chase_detect_height = parseInt((1000/7)*(afframe.width/afframe.height));
            root.center_x = x; root.center_y = y;
            break;
        case afcv_chase_detect_no_disp:
        default:
            chase_detect_rect.visible = false
            break;
        }
    }

    readonly property int afcv_pinpoint_no_disp:            0
    readonly property int afcv_pinpoint_unfoc_prog:         1
    readonly property int afcv_pinpoint_big_green_zoom:     2
    readonly property int afcv_pinpoint_big_green_pip:      3
    readonly property int afcv_pinpoint_big_red_zoom:       4
    readonly property int afcv_pinpoint_big_red_pip:        5
    readonly property int afcv_pinpoint_other_zoom:         6
    readonly property int afcv_pinpoint_other_pip:          7
    readonly property int afcv_pinpoint_green:              8
    readonly property int afcv_pinpoint_red:                9
    readonly property int afcv_pinpoint_default:            10
    function changeValuePinpoint(t,x,y,w,h,p1,p2) {
        LTSubFunction.console_debug.out("changeValuePinpoint t="+t+" x="+x+" y="+y+" w="+w+" h="+h+" p1="+p1+" p2="+p2)
        //if ( (root.mf_pos_x < 0) && (x > 0) ) {
        //    root.mf_pos_x = x
        //}
        //if ( (root.mf_pos_y < 0) && (y > 0) ) {
        //    root.mf_pos_y = y
        //}

        if ((mode == afmode_pinpoint) ||
            (mode == afmode_pinpointf) ){
            root.center_x = x
            root.center_y = y
            root.center_width = w
            root.center_height = h
        }
        else if (mode == afmode_pinpointz) {
            //２．changeValuePinpoint内での計算
            //  afmode_pinpointzの場合、中心座標は拡大領域内カーソル位置をそのまま使用して
            // ください。拡大位置にかかわらず(500,500)が中央になります。
            //  また(0,0)が左上端、(999,999)が右下端です。
            //
            // 一旦、こちらを削除
            //var m = parseInt(deviceAdapter.af_magnify / 10)
            //var x1 = parseInt( ( (root.mf_pos_x + (x - root.mf_pos_x) * m) * 500) / root.mf_pos_x )
            //var y1 = parseInt( ( (root.mf_pos_y + (y - root.mf_pos_y) * m) * 500) / root.mf_pos_y )
            //root.center_x = x1; root.center_y = y1; root.center_width = w; root.center_height = h;
            //LTSubFunction.console_debug.out("changeValuePinpoint mfsx="+root.mf_pos_x+" mfsy="+root.mf_pos_y+" mg="+m+" afw="+afframe.width+" afh="+afframe.height)
            //LTSubFunction.console_debug.out("changeValuePinpoint cx="+root.center_x+" cy="+root.center_y+" cw="+root.center_width+" ch="+root.center_height)
            //
            // 来た値をそのまま使用する。
            root.center_x = x
            root.center_y = y
            root.center_width = w
            root.center_height = h
        }
        //else if ((mode == afmode_pinpointp) && (t != 2) && (t != 3) && (t != 4) && (t != 5) ) {
        else if (mode == afmode_pinpointp) {
            //３．changeValuePinpoint内での計算
            //  afmode_pinpointpの場合、PinP内にx,yを変換する必要があります。
            //  こちらで確認している計算式は下記のようになっています。
            //  x1 = FocusAssist_Pos.pos_x - (FocusAssist_Size.pos_x / 2),
            var x1 = p1 - parseInt(w/2)
            // y1 = FocusAssist_Pos.pos_y - (FocusAssist_Size.pos_y / 2),
            var y1 = p2 - parseInt(h/2)
            // x2 = FocusAssist_Pos.pos_x + ((FocusAssist_Size.pos_x + 1) / 2),
            var x2 = parseInt(p1 + parseInt((w+1)/2))
            // y2 = FocusAssist_Pos.pos_y + ((FocusAssist_Size.pos_y + 1) / 2),
            var y2 = parseInt(p2 + parseInt((h+1)/2))
            // cx = x1 + PinPointAfMagPosX * (x2 - x1) / 1000;
            var cx = x1 + parseInt( (x * (x2 - x1)) / 1000)
            // cy = y1 + PinPointAfMagPosY * (y2 - y1) / 1000;
            var cy = y1 + parseInt( (y * (y2 - y1)) / 1000)
            root.center_x = cx
            root.center_y = cy
            root.center_width = w
            root.center_height = h
            LTSubFunction.console_debug.out("changeValuePinpoint x1="+x1+" y1="+y1+" x2="+x2+" y2="+y2+" cx="+cx+" cy="+cy)
        } else {
            // 来た値をそのまま使用する。
            root.center_x = x
            root.center_y = y
            root.center_width = w
            root.center_height = h
        }
        switch(t) {
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        case afcv_pinpoint_no_disp:
            center_rect.visible = false
            center_plus.visible = false
            break;
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // ピンポイント白表示
        case afcv_pinpoint_unfoc_prog:
            center_rect.visible = false
            center_plus.visible = true
            if(afmode[mode].center_blue){
                center_plus.set_center_blue()
            } else if(afmode[mode].center_blue_s){
                center_plus.set_center_blues()
            } else if(afmode[mode].center_white){
                center_plus.set_center_white()
            }
            else {
                center_plus.set_center_white()
            }
            break;
        //・ピンポイントAF/MFアシスト枠情報の現在のモードが「OFF(0xFFFF)」以外の場合
        // ・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」のいずれかの場合
        //  ピンポイント（アシスト大）表示
        case afcv_pinpoint_big_green_zoom:
        case afcv_pinpoint_big_green_pip:
            center_rect.visible = true
            center_rect.changeMode(center_rect.afmode_sq_normal_green)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            center_plus.visible = false
            break;
        case afcv_pinpoint_big_red_zoom:
        case afcv_pinpoint_big_red_pip:
            center_rect.visible = true
            center_rect.changeMode(center_rect.afmode_sq_normal_red)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_red)
            center_plus.visible = false
            break;
        // ・上記条件に当てはまらない場合
        //  ピンポイント（アシスト）表示
        case afcv_pinpoint_other_zoom:
        case afcv_pinpoint_other_pip:
            center_rect.visible = true
            center_rect.changeMode(center_rect.afmode_sq_normal_green)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            center_plus.set_center_green()

            if (afaeStartFlg) {
                //MF Assist case
                center_plus.visible = false
            } else {
                center_plus.visible = true
            }

            break;
        //・上記条件に当てはまらない場合
        // ピンポイント表示
        //  合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
        //  合焦枠情報の０番目の値が「AF枠表示：緑枠（大)」の場合、緑で表示。
        case afcv_pinpoint_green:
            center_rect.visible = false
            center_plus.visible = true
            center_plus.set_center_green()
            break;
        case afcv_pinpoint_red:
            center_rect.visible = false
            center_plus.visible = true
            center_plus.set_center_red()
            break;
        case afcv_pinpoint_default:
        default:
            center_rect.visible = false
            center_plus.visible = true
            if(afmode[mode].center_blue){
                center_plus.set_center_blue()
            } else if(afmode[mode].center_blue_s){
                center_plus.set_center_blues()
            } else if(afmode[mode].center_white){
                center_plus.set_center_white()
            }
            else {
                center_plus.set_center_white()
            }
            break;
        }
    }

    function changeValueMfz(x,y,w,h) {
        LTSubFunction.console_debug.out("changeValueMfz x="+x+" y="+y+" w="+w+" h="+h)
        // マニュアルフォーカスー全画面でないときカーソルを追従させるならここにコード追加する必要あり 2023/06
        // 全画面でないときカーソルが　取り残される事に対応
        root.center_x = x
        root.center_y = y
        //if ( (root.mf_pos_x < 0) && (x > 0) ) {
        //if (x > 0) {
        //    root.mf_pos_x = x
        //}
        //if ( (root.mf_pos_y < 0) && (y > 0) ) {
        //if (y > 0) {
        //    root.mf_pos_y = y
        //}
    }

    readonly property int afcv_small_frame_no_display:      0
    readonly property int afcv_small_frame_zoom:            1
    readonly property int afcv_small_frame_pinp:            2
    readonly property int afcv_small_frame_default:         3
    function changeValueSmallFrame(v, o_x, o_y, o_w, o_h, m_x, m_y, m_w, m_h) {
        LTSubFunction.console_debug.out("changeValueSmallFrame: outer v=" + v + " x="+ o_x +" y="+ o_y +" w="+ o_w +" h="+o_h)
        LTSubFunction.console_debug.out("changeValueSmallFrame: mag x="+ m_x +" y="+ m_y +" w="+ m_w +" h="+m_h)

        small_frame.outer_x = o_x; small_frame.outer_y = o_y; small_frame.outer_w = o_w; small_frame.outer_h = o_h;
        small_frame.mag_x = m_x; small_frame.mag_y = m_y; small_frame.mag_w = m_w; small_frame.mag_h = m_h;

        switch (v) {
        case afcv_small_frame_zoom:
            small_frame.changeMode(small_frame.afmode_sm_both)
            changeMode(afmode_pscope_z)
            break
        case afcv_small_frame_pinp:
            small_frame.changeMode(small_frame.afmode_sm_init)
            changeMode(afmode_pscope_p)
            break
        case afcv_small_frame_no_display:
        case afcv_small_frame_default:
        default:
            small_frame.changeMode(small_frame.afmode_sm_init)
            break
        }
    }

    readonly property int afcv_pscope_no_disp:          0
    readonly property int afcv_pscope_unfoc_prog:       1
    readonly property int afcv_pscope_big_green:        2
    readonly property int afcv_pscope_big_red:          3
    readonly property int afcv_pscope_white:            4
    readonly property int afcv_pscope_other:            5
    readonly property int afcv_pscope_green:            6
    readonly property int afcv_pscope_red:              7
    readonly property int afcv_pscope_default:          8
    function changeValuePointScopeCenter(t, x, y, w, h) {
        LTSubFunction.console_debug.out("changeValuePointScopeCenter t="+t+" x="+x+" y="+y+" w="+w+" h="+h)

        switch(t) {
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        case afcv_pscope_no_disp:
            center_rect.visible = false
            break
        //合焦枠情報の０番目の値が「AF枠表示：緑枠(大)」の場合、緑で表示。
        // 枠（大）表示
        case afcv_pscope_green:
        case afcv_pscope_big_green:
            center_rect.visible = true

            center_rect.changeMode(center_rect.afmode_sq_normal_green)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_green)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        //合焦枠情報の０番目の値が「AF枠表示：赤枠(大)」の場合、赤で表示。
        // 枠（大）表示
        case afcv_pscope_red:
        case afcv_pscope_big_red:
            center_rect.visible = true

            center_rect.changeMode(center_rect.afmode_sq_normal_red)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_red)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break;
        //合焦枠情報の０番目の値が「AF枠表示：白枠(大)」の場合、白で表示。
        // 枠（大）表示
        case afcv_pscope_white:
            center_rect.visible = true

            center_rect.changeMode(center_rect.afmode_sq_normal_white)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break;

        //合焦枠情報の０番目の値が上記以外の場合、白で表示。
        case afcv_pscope_unfoc_prog:
        case afcv_pscope_other:
        case afcv_pscope_default:
        default:
            center_rect.visible = true

            center_rect.changeMode(center_rect.afmode_sq_normal_white)
            center_aux_rect.changeMode(center_rect.afmode_sq_normal_white)
            root.center_x = x; root.center_y = y; root.center_width = w; root.center_height = h;
            break
        }
    }

    //function changeValueChaseDetect_x(arg) { root.chase_detect_x = arg }
    //function changeValueChaseDetect_y(arg) { root.chase_detect_y = arg }
    //function changeValueChaseDetect_w(arg) { root.chase_detect_width = arg }
    //function changeValueChaseDetect_h(arg) { root.chase_detect_height = arg }
    //function movePositionChaseDetect(arg1, arg2) { root.chase_detect_x += arg1; root.chase_detect_y += arg2;}
    //function movePositionChaseDetect_x(arg) { root.chase_detect_x += arg }
    //function movePositionChaseDetect_y(arg) { root.chase_detect_y += arg }
    //function addValueChaseDetect_w(arg) { root.chase_detect_width += arg }
    //function addValueChaseDetect_h(arg) { root.chase_detect_height += arg }

    function pinpointAfStart() {
        LTSubFunction.console_debug.out("pinpointAfStart")
//        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
//            //アシストモード：PinP        2
//            // モードをafmode_pinpointpに変える
//            changeMode(afmode_pinpointp)
//        } else {
//            //アシストモード：ズーム      1
//            // モードをafmode_pinpointzに変える
//            //root.mf_pos_x = -1
//            //root.mf_pos_y = -1
//            changeMode(afmode_pinpointz)
//        }
        // ピンポイント設定APIを呼ぶ
        deviceAdapter.afFrame_pos_pin_X = root.center_x
        deviceAdapter.afFrame_pos_pin_Y = root.center_y
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_AF_START()
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMSTART();
    }

    function pinpointAfEnd() {
        LTSubFunction.console_debug.out("pinpointAfEnd")
        //root.mf_pos_x = -1
        //root.mf_pos_y = -1
//        changeMode(afmode_pinpoint)
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_AF_STOP()
    }

    function pScopeStart() {
        LTSubFunction.console_debug.out("pScopeStart")

        var ret = true
        // ピンポイント設定APIを呼ぶ
        var ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PSCOPE_START()

        if (ret1 == LT.DeviceAdapter.Ternary_True) {
            //back up mode to change back
            mode_pscope_bk = mode
            changeMode(afmode_pscope)
        } else {
//            mfAssistStartError()
            ret = false
        }

        return ret
    }

    function pScopeEnd() {
        LTSubFunction.console_debug.out("pScopeEnd")

        var ret = true

        // ピンポイント設定APIを呼ぶ
        dispFrame()
        var ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PSCOPE_END()
        if (ret1 == LT.DeviceAdapter.Ternary_True) {
//            changeMode(afmode_init)
        } else {
            ret = false
        }

        return ret
    }

    function mfStart() {
        LTSubFunction.console_debug.out("mfStart")
        var assist = 0
        if(deviceAdapter.mfAssistMode == LT.Utilities.MFASTM_Pinp) {
            //アシストモード：PinP        2
            // モードをafmode_mfpに変える
            //changeMode(afmode_mfp)
            assist = LT.Utilities.RcMfaMode_Pinp
        } else {
            //アシストモード：ズーム      1
            // モードをafmode_mfzに変える
            //root.mf_pos_x = -1
            //root.mf_pos_y = -1
            //changeMode(afmode_mfz)
            assist = LT.Utilities.RcMfaMode_Zoom
        }
        // ピンポイント設定APIを呼ぶ
        deviceAdapter.mfFrame_pos_X = root.center_x
        deviceAdapter.mfFrame_pos_Y = root.center_y
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_START_REQ(assist)
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
    }

    function mfAdjust() {
        LTSubFunction.console_debug.out("mfAdjust")
        if(deviceAdapter.mfAssistMode == LT.Utilities.MFASTM_Pinp) {
            //アシストモード：PinP        2
            // モードをafmode_mfpに変える
            if(mode != afmode_mfp) {
                //changeMode(afmode_mfp)
            }
        } else {
            //アシストモード：ズーム      1
            // モードをafmode_mfzに変える
            if(mode != afmode_mfz) {
                //root.mf_pos_x = -1
                //root.mf_pos_y = -1
                //changeMode(afmode_mfz)
            }
        }
    }

    function mfEnd() {
        LTSubFunction.console_debug.out("mfEnd")
//        changeMode(afmode_mf)
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_END_REQ()
    }

    function afmfStart() {
        LTSubFunction.console_debug.out("afmfStart")
        dispFrame()
        // ピンポイント設定APIを呼ぶ
        deviceAdapter.mfFrame_pos_X = root.center_x
        deviceAdapter.mfFrame_pos_Y = root.center_y
        switch(deviceAdapter.mfAssistMode) {
        case LT.Utilities.MFASTM_Normal:
            if(deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_START_REQ(LT.Utilities.RcMfaMode_Zoom) == LT.DeviceAdapter.Ternary_True) {
                pinpointZoom.visible = true
            } else {
//                mfAssistStartError()
                return false
            }
            break;
        case LT.Utilities.MFASTM_Pinp:
            if(deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_START_REQ(LT.Utilities.RcMfaMode_Pinp) == LT.DeviceAdapter.Ternary_False) {
//                mfAssistStartError()
                return false
            }
            break;
        }
        var ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
        return ret3
    }

    function afmfEnd() {
        LTSubFunction.console_debug.out("afmfEnd")
        //afaeStartFlg = false
        pinpointZoom.visible = false
        dispFrame()
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_END_REQ()
    }

    // 動画LV拡大開始
    function lvMagStart() {
        LTSubFunction.console_debug.out("lvMagStart")
        var assist = 0
        if(deviceAdapter.lvMagMode == LT.Utilities.LVMM_Pinp) {
            //アシストモード：PinP        2
            assist = LT.Utilities.RcLVMMode_Pinp
        } else {
            //アシストモード：ズーム      1
            assist = LT.Utilities.RcLVMMode_Zoom
        }
        deviceAdapter.lvMag_pos_X = root.center_x
        deviceAdapter.lvMag_pos_Y = root.center_y
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_START_REQ(assist)
    }

    // 動画LV拡大終了
    function lvMagEnd() {
        LTSubFunction.console_debug.out("lvMagEnd")
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_END_REQ()
    }

    function afoff() {
        if(afaeStartFlg) {
            return
        }
        switch(mode) {
        case afmode_pointone://
        // ivc >> start >> No.3 -> nakhuong
        case afmode_pointone_aux://
        // ivc << end << No.3 -> nakhuong
        case afmode_point225://
        case afmode_point225s://
        case afmode_point225s_af://
        case afmode_point225f://
        case afmode_point225sf://
        case afmode_point225sf_af://
        case afmode_face_225://
        case afmode_face_225f://
            // ここでは何もしない
            break;
        case afmode_point225_af://
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            afframe225.disp_clear()
            // モードをafmode_point225に変える
            changeMode(afmode_point225)
            break;
        case afmode_face_225_af://
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            afframe225.disp_clear()
            // モードをafmode_face_225に変える
            changeMode(afmode_face_225)
            break;
        case afmode_point225f_af://
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            afframe225.disp_clear()
            // モードをafmode_point225fに変える
            changeMode(afmode_point225f)
            break;
        case afmode_face_225f_af://
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            afframe225.disp_clear()
            // モードをafmode_face_225fに変える
            changeMode(afmode_face_225f)
            break;
        case afmode_face://
        case afmode_face_eye://
            // ここでは何もしない
            break;
        case afmode_face_af://       5
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            // モードをafmode_face_afに変える
            changeMode(afmode_face)
            break;
        case afmode_chase://         6
            // ここでは何もしない
            break;
        case afmode_chase_af://      7
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            // モードをafmode_chase_afに変える
            changeMode(afmode_chase)
            break;
        case afmode_pinpoint://      8
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            break;
        case afmode_pinpointf://     9
        case afmode_pinpointz://     9
        case afmode_pinpointp://     9
            // ここでは何もしない
            break;
        case afmode_custom:
        case afmode_customs:
        case afmode_custom_af:
        case afmode_customs_af:
        case afmode_customf:
        case afmode_customsf:
        case afmode_customf_af:
        case afmode_customsf_af:
        case afmode_customo:
        case afmode_customo_af:
        case afmode_customof:
        case afmode_customof_af:
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            break;
        case afmode_mf://            12
        case afmode_mff://           13
        case afmode_mfz://           13
        case afmode_mfp://           13
            // ここでは何もしない
            break;
        case afmode_fullarea_af://
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            afframe225.disp_clear()
            // モードをafmode_fullareaに変える
            changeMode(afmode_fullarea)
            break;
        case afmode_fullareaf_af://
            // AF OFF APIを呼ぶ
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AF_OFF();
            if(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show) {
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_AFAE_OFF();
            }
            afframe225.disp_clear()
            // モードをafmode_fullareafに変える
            changeMode(afmode_fullareaf)
            break;
        default:
            // ここでは何もしない
            break;
        }
    }

    function changeMode(arg) {
        // フレームドラッグ中にafmode_mfに変更される場合END_REQ送信
        if(arg == afmode_mf && frameMsArea.pressed){
            LTSubFunction.console_debug.out("AFFrame changeMode: afmode_mf & frame drag")
            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_END_REQ()
        }

        if (arg == afmode_mf || arg == afmode_mfp || arg == afmode_mfz) {
            LTSubFunction.console_debug.out("AFFrame changeMode: mode mf=" + arg)
            mode_pscope_bk = afmode_init
            mode = arg
        } else if (deviceAdapter.afPointScopeEnable && deviceAdapter.sFrame_info
            && arg != afmode_pscope && arg != afmode_pscope_p && arg != afmode_pscope_z) {
            LTSubFunction.console_debug.out("AFFrame changeMode: mode bk=" + arg)
            mode_pscope_bk = arg
        } else {
            LTSubFunction.console_debug.out("AFFrame changeMode: mode = " + arg)
            mode = arg
        }
        //mode_label.text = afmode[mode].name
        dispAfOff()
        dispFrame()
    }

    function dispFrame() {
        LTSubFunction.console_debug.out("dispFrame mode="+mode+" afae="+afaeStartFlg)
        var frames = afframe225.point225_Frame

        if(afmode[mode].center_blue){
            LTSubFunction.console_debug.out("dispFrame center_blue center_keep: " + center_keep)
            center_plus.set_center_blue()
            center_plus.visible = true
        } else if(afmode[mode].center_blue_s){
            LTSubFunction.console_debug.out("dispFrame center_blue_s")
            center_plus.set_center_blues()
            center_plus.visible = true
        } else if(afmode[mode].center_white){
            LTSubFunction.console_debug.out("dispFrame center_white now="+center_plus_rect1.color)
            //center_plus.set_center_white()
            if((center_plus_rect1.color !== LTSubFunction.afFrameColorPalette.green)&&(center_plus_rect1.color != "#008000")) {
                center_plus.set_center_white()
            }

            center_plus.visible = true
//            if((afaeStartFlg)
//               &&(mfzoom_mode != mfzoom_mode_unknown)
//               &&(mode == afmode_pinpoint
//                  || mode == afmode_pinpointp
//                  || mode == afmode_pinpointp)) {
//                center_plus.visible = false
//            } else {
//                center_plus.visible = true
//            }
        } else {
            LTSubFunction.console_debug.out("dispFrame center_no")
            center_plus.visible = false
        }
        if(afmode[mode].frame_one){
            LTSubFunction.console_debug.out("dispFrame frame_one")
            center_rect.visible = true
        } else {
            LTSubFunction.console_debug.out("dispFrame frame_one_no")
            center_rect.visible = false
        }
        // ivc >> start >> No.3 -> nakhuong
        if(afmode[mode].frame_one_aux){
            LTSubFunction.console_debug.out("dispFrame frame_one_aux")
            center_rect.visible = true
            center_aux_rect.visible = true
        } else {
            LTSubFunction.console_debug.out("dispFrame frame_one_aux_no")
            center_aux_rect.visible = false
        }
        // ivc << end << No.3 -> nakhuong
        if(root.center_width * root.center_height == 0) {
            LTSubFunction.console_debug.out("dispFrame size=0 frame_one_no")
            center_rect.visible = false
        }
        //if(afaeStartFlg) {
        //    console.debug("dispFrame afae=ON frame_one_no")
        //    center_rect.visible = false
        //}
        // ivc >> start >> #8552
//        // ivc >> start >> No.3
//        if((deviceAdapter.afcStartPosState == LT.Utilities.AfcStartPosStatus_ON)
//            && (deviceAdapter.autoFocusMode == LT.Utilities.AFM_225Point)
//            && (deviceAdapter.focusMode == LT.Utilities.FM_AF_C)) {
//            center_plus.visible = true
//        } else {
//            center_plus.visible = false
//        }
//        // ivc << end << No.3
        // ivc << end << #8552

        if(afmode[mode].frame_face){
            LTSubFunction.console_debug.out("dispFrame frame_face")
            face_rect.changeMode(center_rect.afmode_sq_normal_white)
            face_rect.changeVisible(true)
        } else {
            LTSubFunction.console_debug.out("dispFrame frame_face_no")
            face_rect.changeMode(center_rect.afmode_sq_init)
            face_rect.changeVisible(false)
        }
        if((afaeStartFlg)&&(mfzoom_mode != mfzoom_mode_unknown)) {
            LTSubFunction.console_debug.out("dispFrame afae=ON frame_face_no")
            face_rect.changeMode(center_rect.afmode_sq_init)
            face_rect.changeVisible(false)
        }
        // 自動認識ON/OFF有効
        if(deviceAdapter.automaticRecoEnable &&
           deviceAdapter.autoRecognizeGeneralEnable){
            face_rect.changeMode(center_rect.afmode_sq_init)
            face_rect.changeVisible(true)
        // 認識切替有効
        }else if(deviceAdapter.autoRecognizeGeneralEnable){
            face_rect.changeMode(center_rect.afmode_sq_init)
            face_rect.changeVisible(true)
        }
        // iAモード(MFアシストモード：OFF)
        if(deviceAdapter.recordingMode === LT.Utilities.RM_IntelligentAuto &&
           deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Off){
            face_rect.changeMode(center_rect.afmode_sq_init)
            face_rect.changeVisible(true)
        }

        if(afmode[mode].frame_chase) {
            LTSubFunction.console_debug.out("dispFrame frame_chase")
            if(chase_detect_rect.sq_mode == center_rect.afmode_sq_chase_yellow) {
                chase_detect_rect.changeMode(center_rect.afmode_sq_chase_white)
            }
            chase_detect_rect.visible = true
        } else if(afmode[mode].frame_chase_af) {
            LTSubFunction.console_debug.out("dispFrame frame_chase_af")
            if(chase_detect_rect.sq_mode != center_rect.afmode_sq_chase_green) {
                chase_detect_rect.changeMode(center_rect.afmode_sq_chase_yellow)
            }
            chase_detect_rect.visible = true
        } else {
            LTSubFunction.console_debug.out("dispFrame frame_chase_no")
            chase_detect_rect.visible = false
        }
        if((afaeStartFlg)&&(mfzoom_mode != mfzoom_mode_unknown)) {
            LTSubFunction.console_debug.out("dispFrame afae=ON frame_chase_no")
            chase_detect_rect.visible = false
        }

        if(afmode[mode].frame_pinpoint){
            LTSubFunction.console_debug.out("dispFrame frame_pinpoint")
            pinpointZoom.visible = true
        } else {
            LTSubFunction.console_debug.out("dispFrame frame_pinpoint_no")
            pinpointZoom.visible = false
        }
        if((afaeStartFlg)&&(mfzoom_mode != mfzoom_mode_unknown)) {
            LTSubFunction.console_debug.out("dispFrame afae=ON frame_pinpoint_no")
            pinpointZoom.visible = false
        }

        if(afmode[mode].frame_225){
            LTSubFunction.console_debug.out("dispFrame frame_225")
            zone_outer.visible = false
            if(dispPDAF){
//console.debug("afframePDAF.visible true6")
                afframe225.visible = false
                afframePDAF.visible = true
            }else{
                afframe225.visible = true
                afframePDAF.visible = false
            }
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            if( f225_timer.running == true ) {
                var start_x = Math.max(0, f225_pos_x - parseInt(f225_length/2));
                var end_x = Math.min(afframe225.f225_x_num-1, f225_pos_x + parseInt(f225_length/2));
                var start_y = Math.max(0, f225_pos_y - parseInt(f225_length/2));
                var end_y = Math.min(afframe225.f225_y_num-1, f225_pos_y + parseInt(f225_length/2));
                afframe225.changeModeSelectArea(start_x, start_y, end_x, end_y, frames[0].mode_yellow)
            }
        }
        else if(afmode[mode].frame_225f){
            LTSubFunction.console_debug.out("dispFrame frame_225f")
            zone_outer.visible = false
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            if(dispPDAF){
                afframe225.visible = false
                afframePDAF.visible = true
            }else{
                afframe225.visible = true
                afframePDAF.visible = false
                var start_x = Math.max(0, f225_pos_x - parseInt(f225_length/2));
                var end_x = Math.min(afframe225.f225_x_num-1, f225_pos_x + parseInt(f225_length/2));
                var start_y = Math.max(0, f225_pos_y - parseInt(f225_length/2));
                var end_y = Math.min(afframe225.f225_y_num-1, f225_pos_y + parseInt(f225_length/2));
                afframe225.changeModeSelectArea(start_x, start_y, end_x, end_y, frames[0].mode_lightgray)
                //for(var i = 0; i < f225_x_num*f225_y_num; i ++) {
                //    if( (frames[i].mode == frames[i].mode_yellow) || (frames[i].mode == frames[i].mode_green_b) || (frames[i].mode == frames[i].mode_lightgray) || (frames[i].mode == frames[i].mode_gray) ) {
                //        frames[i].visible = true
                //    } else {
                //        frames[i].visible = false
                //    }
                //}
            }
        }
        else if(afmode[mode].frame_225s){
            LTSubFunction.console_debug.out("dispFrame frame_225s")
            zone_outer.visible = false
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            if(dispPDAF){
                afframe225.visible = false
                afframePDAF.visible = true
            }else{
                afframe225.visible = true
                afframePDAF.visible = false
                var start_x = Math.max(0, f225_pos_x - parseInt(f225_length/2));
                var end_x = Math.min(afframe225.f225_x_num-1, f225_pos_x + parseInt(f225_length/2));
                var start_y = Math.max(0, f225_pos_y - parseInt(f225_length/2));
                var end_y = Math.min(afframe225.f225_y_num-1, f225_pos_y + parseInt(f225_length/2));
                afframe225.changeModeSelectArea(start_x, start_y, end_x, end_y, frames[0].mode_lightgray)
                //for(var i = 0; i < f225_x_num*f225_y_num; i ++) {
                //    if( (frames[i].mode == frames[i].mode_yellow) || (frames[i].mode == frames[i].mode_green_b) || (frames[i].mode == frames[i].mode_lightgray) || (frames[i].mode == frames[i].mode_gray) ) {
                //        frames[i].visible = true
                //    } else {
                //        frames[i].visible = false
                //    }
                //}
            }
        }
        else if(afmode[mode].frame_custom){
            LTSubFunction.console_debug.out("dispFrame frame_custom")
            zone_outer.visible = false
            afframe225.visible = true
            afframe225.disp_clear()
            afframePDAF.visible = false
            afframePDAF.disp_clear()
        }
        else if(afmode[mode].frame_customf){
            LTSubFunction.console_debug.out("dispFrame frame_customf")
            zone_outer.visible = false
            afframe225.visible = true
            afframePDAF.visible = false
            afframePDAF.disp_clear()
            /*
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
                frames[i].visible = true
            }
            var start_x = Math.max(0, f225_pos_x - parseInt(f225_length/2));
            var end_x = Math.min(f225_x_num-1, f225_pos_x + parseInt(f225_length/2));
            var start_y = Math.max(0, f225_pos_y - parseInt(f225_length/2));
            var end_y = Math.min(f225_y_num-1, f225_pos_y + parseInt(f225_length/2));
            for(var i = start_x; i <= end_x; i ++) {
                for(var j = start_y; j <= end_y; j ++) {
                    frames[ j * f225_x_num + i ].changeMode(frames[ j * f225_x_num + i ].mode_lightgray)
                    //frames[ j * f225_x_num + i ].visible = true
                }
            }*/
            //for(var i = 0; i < f225_x_num*f225_y_num; i ++) {
            //    if( (frames[i].mode == frames[i].mode_yellow) || (frames[i].mode == frames[i].mode_green_b) || (frames[i].mode == frames[i].mode_lightgray) || (frames[i].mode == frames[i].mode_gray) ) {
            //        frames[i].visible = true
            //    } else {
            //        frames[i].visible = false
            //    }
            //}
        }
        else if(afmode[mode].frame_outer){
            LTSubFunction.console_debug.out("dispFrame frame_outer")
            zone_outer.visible = true
            zone_outer.changeDisp(false)
            if(dispPDAF){
                afframe225.visible = false
                afframePDAF.visible = true
            }else{
                afframe225.visible = true
                afframePDAF.visible = false
            }
            afframe225.disp_clear()
            afframePDAF.disp_clear()
        }
        else if(afmode[mode].frame_outerf){
            LTSubFunction.console_debug.out("dispFrame frame_outerf")
            zone_outer.visible = true
            zone_outer.changeDisp(true)
            if(dispPDAF){
                afframe225.visible = false
 //console.debug("afframePDAF.visible true10")
                afframePDAF.visible = true
            }else{
                afframe225.visible = true
                afframePDAF.visible = false
            }
        }
        else {
            LTSubFunction.console_debug.out("dispFrame frame_225_no")
            zone_outer.visible = false
            afframe225.visible = false
            afframePDAF.visible = false
        }
        //if((afaeStartFlg)&&(mfzoom_mode != mfzoom_mode_unknown)) {
        //    LTSubFunction.console_debug.out("dispFrame afae=ON frame_225_no")
        //    afframe225.visible = false
        //}
        afframe225.point225_Frame = frames

        if (afmode[mode].frame_small) {
            small_frame.visible = true
        } else {
            small_frame.visible = false
        }

        if (afmode[mode].frame_drag) {
            frame_drag.visible = true
        } else {
            frame_drag.visible = false
        }

        //測光モード変更されたときの十字マークの表示位置を更新してやる
        if( center_plus.visible === true && zone_outer.visible === true ){
            zone_outer.zone_center_disp()
        }else if( center_plus.visible === true && afframe225.visible === true){
            af_frame_info_Changed()
        }
    }

    function magnify_pos_set(posX, posY){
        var ret = false

        // 拡大位置設定
        if(mode == afmode_mfz
            || (afaeStartFlg && mode == afmode_pinpointz)){
            deviceAdapter.mfFrame_pos_X = posX
            deviceAdapter.mfFrame_pos_Y = posY
            ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
        }else if(mode == afmode_pinpointz) {
            deviceAdapter.afFrame_pos_pin_X = posX
            deviceAdapter.afFrame_pos_pin_Y = posY
            ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_MOVE_POS()
        }else if(mode == afmode_lvmag_z) {
            deviceAdapter.lvMag_pos_X = posX
            deviceAdapter.lvMag_pos_Y = posY
            ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MOVE_REQ()
        }

        return ret
    }

    function afmode_point225f_center_disp() {
        // PDAF時は画像中心・ゾーン中心・簡易1点座標が使用される
        if(!dispPDAF){
            afframe225.afmode_point225f_center_disp()
        }
    }

    readonly property int aspectRatio_unknown: 0
    readonly property int aspectRatio_4_3: 1
    readonly property int aspectRatio_3_2: 2
    readonly property int aspectRatio_16_9: 3
    readonly property int aspectRatio_1_1: 4
    readonly property int aspectRatio_17_9: 5
    readonly property int aspectRatio_2_4_1: 6
    // アスペクト比を取得(AF枠数が315点、PDAFのとき)
    function getImgAspectRatio() {
        // 画像からアスペクト比を計算
        var ratio = 0.0
        if (imageLV.paintedWidth < imageLV.paintedHeight) {
            ratio = imageLV.paintedHeight / imageLV.paintedWidth
        } else {
            ratio = imageLV.paintedWidth / imageLV.paintedHeight
        }
        
        var ratio4_3 = 4 / 3
        var ratio3_2 = 3 / 2
        var ratio16_9 = 16 / 9
        var ratio1_1 = 1 / 1
        var ratio17_9 = 17 / 9
        var ratio2_4_1 = 2.4 / 1
        if(ratio.toFixed(1) == ratio4_3.toFixed(1)) {
            return aspectRatio_4_3
        }
        else if(ratio.toFixed(1) == ratio3_2.toFixed(1)) {
            return aspectRatio_3_2
        }
        else if(ratio.toFixed(1) == ratio16_9.toFixed(1)) {
            return aspectRatio_16_9
        }
        else if(ratio.toFixed(1) == ratio1_1.toFixed(1)) {
            return aspectRatio_1_1
        }
        else if(ratio.toFixed(1) == ratio17_9.toFixed(1)) {
            return aspectRatio_17_9
        }
        else if(ratio.toFixed(1) == ratio2_4_1.toFixed(1)) {
            return aspectRatio_2_4_1
        }
        return aspectRatio_unknown;
    }

    // AF枠の最大列数を取得する
    readonly property int frame225SplitMaxNumX: 15
    readonly property int frame315SplitMaxNumX: 21
    readonly property int frame779SplitMaxNumX: 41
    // AF情報：AF合焦枠
    function getAFDispSplitMaxNumX() {
        if(dispPDAF) {
            return frame779SplitMaxNumX
        } else if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return frame315SplitMaxNumX
        } else {
            return frame225SplitMaxNumX
        }
    }
    // AF枠設定：カスタムマルチ
    function getCMultiSplitMaxNumX() {
        if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return frame315SplitMaxNumX
        } else {
            return frame225SplitMaxNumX
        }
    }
    // AF枠の最大行数を取得する
    readonly property int frame225SplitMaxNumY: 15
    readonly property int frame315SplitMaxNumY: 15
    readonly property int frame779SplitMaxNumY: 19
    // AF情報：AF合焦枠
    function getAFDispSplitMaxNumY() {
        if(dispPDAF) {
            return frame779SplitMaxNumY
        } else {
            return frame225SplitMaxNumY
        }
    }
    // AF枠設定：カスタムマルチ
    function getCMultiSplitMaxNumY() {
        return frame225SplitMaxNumY
    }

    // 315点表示のパラメータテーブル
    // 各数値は本体ファームの設計書を参照。
    // table[センサ種類][パラメータ種類][アスペクト比]
    // センサ種類：
    //   0->フルサイズ
    //   1->マイクロフォーサーズ
    // パラメータ種類：
    //   0->AF枠の列数
    //   1->AF枠の行数
    //   2->基準の解像度(幅)
    //   3->基準の解像度(高さ)
    //   4->AF枠設定範囲のマージン（左右）
    //   5->AF枠設定範囲のマージン（上下）
    // アスペクト比：
    //   0->unknown(デフォルト)
    //   1->4:3
    //   2->3:2
    //   3->16:9
    //   4->1:1
    //   5->17:9
    property variant f315_param_table: [
        // フルサイズ
        [
            [21, 19, 21, 21, 13, 21, 21],  // AF枠の列数
            [15, 15, 15, 13, 15, 13, 9],  // AF枠の行数
            [720, 640, 720, 720, 480, 720, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 381, 304],  // 基準の解像度(高さ)
            [48/2, 32/2, 48/2, 48/2, 64/2, 48/2, 48/2],  // AF枠設定範囲のマージン（左右）
            [60/2, 60/2, 60/2, 40/2, 60/2, 17/2, 52/2]  // AF枠設定範囲のマージン（上下）
        ],
        // マイクロフォーサーズ
        [
            [21, 21, 21, 21, 15, 21, 21],  // AF枠の列数
            [15, 15, 13, 11, 15, 11, 9],  // AF枠の行数
            [640, 640, 720, 720, 480, 720, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 381, 301],  // 基準の解像度(高さ)
            [52/2, 52/2, 48/2, 48/2, 30/2, 48/2, 48/2],  // AF枠設定範囲のマージン（左右）
            [60/2, 60/2, 64/2, 52/2, 30/2, 29/2, 13/2]  // AF枠設定範囲のマージン（上下）
        ]
    ]
    // 315点行列数変更
    // 現在の行列数とアスペクト比からセンサ種類を判定する
    function frame315FrameNumSetting(numX, numY) {
        var sensor = sensorType_MFTS
        
        var aspect = getImgAspectRatio()
        // 4:3
        if(aspect === aspectRatio_4_3){
            // mFTS
            if(numX === f315_param_table[sensorType_MFTS][0][aspectRatio_4_3] &&
               numY === f315_param_table[sensorType_MFTS][1][aspectRatio_4_3]){
                sensor = sensorType_MFTS
            // Full
            }else if(numX === f315_param_table[sensorType_Full][0][aspectRatio_4_3] &&
                     numY === f315_param_table[sensorType_Full][1][aspectRatio_4_3]){
                sensor = sensorType_Full
            }
        // 3:2
        }else if(aspect === aspectRatio_3_2){
            // mFTS
            if(numX === f315_param_table[sensorType_MFTS][0][aspectRatio_3_2] &&
               numY === f315_param_table[sensorType_MFTS][1][aspectRatio_3_2]){
                sensor = sensorType_MFTS
            // Full
            }else if(numX === f315_param_table[sensorType_Full][0][aspectRatio_3_2] &&
                     numY === f315_param_table[sensorType_Full][1][aspectRatio_3_2]){
                sensor = sensorType_Full
            }
        // 16:9
        }else if(aspect === aspectRatio_16_9){
            // mFTS
            if(numX === f315_param_table[sensorType_MFTS][0][aspectRatio_16_9] &&
               numY === f315_param_table[sensorType_MFTS][1][aspectRatio_16_9]){
                sensor = sensorType_MFTS
            // Full
            }else if(numX === f315_param_table[sensorType_Full][0][aspectRatio_16_9] &&
                     numY === f315_param_table[sensorType_Full][1][aspectRatio_16_9]){
                sensor = sensorType_Full
            }
        // 1:1
        }else if(aspect === aspectRatio_1_1){
            // mFTS
            if(numX === f315_param_table[sensorType_MFTS][0][aspectRatio_1_1] &&
               numY === f315_param_table[sensorType_MFTS][1][aspectRatio_1_1]){
                sensor = sensorType_MFTS
            // Full
            }else if(numX === f315_param_table[sensorType_Full][0][aspectRatio_1_1] &&
                     numY === f315_param_table[sensorType_Full][1][aspectRatio_1_1]){
                sensor = sensorType_Full
            }
        // 17:9
        }else if(aspect === aspectRatio_17_9){
            // mFTS
            if(numX === f315_param_table[sensorType_MFTS][0][aspectRatio_17_9] &&
               numY === f315_param_table[sensorType_MFTS][1][aspectRatio_17_9]){
                sensor = sensorType_MFTS
            // Full
            }else if(numX === f315_param_table[sensorType_Full][0][aspectRatio_17_9] &&
                     numY === f315_param_table[sensorType_Full][1][aspectRatio_17_9]){
                sensor = sensorType_Full
            }
        // 2.4:1
        }else if(aspect === aspectRatio_2_4_1){
            // mFTS
            if(numX === f315_param_table[sensorType_MFTS][0][aspectRatio_2_4_1] &&
               numY === f315_param_table[sensorType_MFTS][1][aspectRatio_2_4_1]){
                sensor = sensorType_MFTS
            // Full
            }else if(numX === f315_param_table[sensorType_Full][0][aspectRatio_2_4_1] &&
                     numY === f315_param_table[sensorType_Full][1][aspectRatio_2_4_1]){
                sensor = sensorType_Full
            }
        }
        sensorType = sensor
    }

    // PDAF表示のパラメータテーブル
    // 各数値は本体ファームの設計書を参照。
    // table[レンズ種類][パラメータ種類][アスペクト比]
    // レンズ種類：
    //   0->FFレンズ
    //   1->APS-Cレンズ
    //   2->mFTSレンズ
    // パラメータ種類：
    //   0->AF枠の列数
    //   1->AF枠の行数
    //   2->基準の解像度(幅)
    //   3->基準の解像度(高さ)
    //   4->中心点距離(X)
    //   5->中心点距離(Y)
    //   6->緑枠サイズ(幅)
    //   7->緑枠サイズ(高さ)
    // アスペクト比：
    //   0->unknown(デフォルト)
    //   1->4:3
    //   2->3:2
    //   3->16:9
    //   4->1:1
    //   5->17:9
    // PDAFのパラメータテーブルの種類
    readonly property int pdaf_tableType_full: 0  // 通常(L FULL)
    readonly property int pdaf_tableType_exM: 1  // M EXテレコン1.4
    readonly property int pdaf_tableType_exS: 2  // S EXテレコン2.0
    property int pdaf_tableType: pdaf_tableType_full
    //緑枠サイズの見た目が小さく見えるので本体から提示された値＋1としておく
    // 通常(L FULL)
    property variant f779_param_table_full: [
        // FFレンズ
        [
            [41, 35, 41, 41, 25, 41],  // AF枠の列数
            [19, 19, 19, 17, 19, 17],  // AF枠の行数
            [720, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [15, 15, 15, 15, 15, 15],  // 中心点距離(X)
            [23, 23, 23, 23, 23, 23],  // 中心点距離(Y)
            [11, 11, 11, 11, 11, 11],  // 緑枠サイズ(幅)
            [11, 11, 11, 11, 11, 11]  // 緑枠サイズ(高さ)
        ],
        // APS-Cレンズ
        [
            [25, 21, 25, 25, 15, 25],  // AF枠の列数
            [13, 13, 13, 11, 13, 11],  // AF枠の行数
            [720, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [23, 23, 23, 23, 23, 23],  // 中心点距離(X)
            [35, 35, 35, 35, 35, 35],  // 中心点距離(Y)
            [16, 16, 16, 16, 16, 16],  // 緑枠サイズ(幅)
            [16, 16, 16, 16, 16, 16]  // 緑枠サイズ(高さ)
        ],
        // mFTSレンズ
        [
            [41, 41, 41, 41, 29, 41],  // AF枠の列数
            [19, 19, 19, 15, 19, 15],  // AF枠の行数
            [640, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [14, 14, 15, 15, 14, 15],  // 中心点距離(X)
            [21, 21, 23, 23, 21, 23],  // 中心点距離(Y)
            [11, 11, 12, 12, 11, 12],  // 緑枠サイズ(幅)
            [11, 11, 12, 12, 11, 12]  // 緑枠サイズ(高さ)
        ]
    ]
    // M EXテレコン1.4
    property variant f779_param_table_exM: [
        // FFレンズ
        [
            [27, 23, 27, 27, 17, 27],  // AF枠の列数
            [13, 13, 13, 11, 13, 11],  // AF枠の行数
            [720, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [21, 21, 21, 21, 21, 21],  // 中心点距離(X)
            [32, 32, 32, 32, 32, 32],  // 中心点距離(Y)
            [15, 15, 15, 15, 15, 15],  // 緑枠サイズ(幅)
            [15, 15, 15, 15, 15, 15]  // 緑枠サイズ(高さ)
        ],
        // APS-Cレンズ
        [
            [17, 15, 17, 17, 9, 17],  // AF枠の列数
            [ 9,  9,  9,  7, 9,  7],  // AF枠の行数
            [720, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [32, 32, 32, 32, 32, 32],  // 中心点距離(X)
            [49, 49, 49, 49, 49, 49],  // 中心点距離(Y)
            [22, 22, 22, 22, 22, 22],  // 緑枠サイズ(幅)
            [22, 22, 22, 22, 22, 22]  // 緑枠サイズ(高さ)
        ],
        // mFTSレンズ
        [
            [29, 29, 29, 29, 21, 29],  // AF枠の列数
            [15, 15, 13, 11, 15, 11],  // AF枠の行数
            [640, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [19, 19, 22, 22, 19, 22],  // 中心点距離(X)
            [30, 30, 33, 33, 30, 33],  // 中心点距離(Y)
            [15, 15, 17, 17, 15, 17],  // 緑枠サイズ(幅)
            [16, 16, 17, 17, 16, 17]  // 緑枠サイズ(高さ)
        ]
    ]
    // S EXテレコン2.0
    property variant f779_param_table_exS: [
        // FFレンズ
        [
            [17, 15, 17, 17, 9, 17],  // AF枠の列数
            [ 9,  9,  9,  7, 9,  7],  // AF枠の行数
            [720, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [30, 30, 30, 30, 30, 30],  // 中心点距離(X)
            [46, 46, 46, 46, 46, 46],  // 中心点距離(Y)
            [21, 21, 21, 21, 21, 21],  // 緑枠サイズ(幅)
            [21, 21, 21, 21, 21, 21]  // 緑枠サイズ(高さ)
        ],
        // APS-Cレンズ
        [
            [11, 9, 11, 9, 5, 9],  // AF枠の列数
            [ 7, 7,  7, 5, 7, 5],  // AF枠の行数
            [720, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [46, 44, 46, 48, 46, 48],  // 中心点距離(X)
            [70, 67, 70, 74, 70, 70],  // 中心点距離(Y)
            [31, 30, 31, 33, 31, 33],  // 緑枠サイズ(幅)
            [31, 30, 31, 33, 31, 33]  // 緑枠サイズ(高さ)
        ],
        // mFTSレンズ
        [
            [19, 19, 19, 19, 13, 19],  // AF枠の列数
            [ 9,  9,  9,  7,  9,  7],  // AF枠の行数
            [640, 640, 720, 720, 480, 720],  // 基準の解像度(幅)
            [480, 480, 480, 404, 480, 404],  // 基準の解像度(高さ)
            [27, 27, 31, 31, 27, 31],  // 中心点距離(X)
            [41, 41, 46, 46, 41, 46],  // 中心点距離(Y)
            [20, 20, 23, 23, 20, 23],  // 緑枠サイズ(幅)
            [21, 21, 24, 24, 21, 24]  // 緑枠サイズ(高さ)
        ],
    ]
    function pdafInfoSetting(){
        // PDAF合焦情報を表示するかどうか
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            dispPDAF = true
        }else{
            dispPDAF = false
        }
    }

    function pdafTableTypeSetting(){
        // PDAFパラメータテーブル選択
        if(deviceAdapter.exTelecon === LT.Utilities.EXT_Converter){
            var picSize = deviceAdapter.pictureSize
            if((picSize & 0x00008000) == 0x00008000){  // 拡張ズームフラグ確認
                switch ((picSize & 0x00000F00) >> 8) {
                case 1:  // M
                    pdaf_tableType = pdaf_tableType_exM
                    break
                case 2:  // S
                    pdaf_tableType = pdaf_tableType_exS
                    break
                default:
                    pdaf_tableType = pdaf_tableType_full
                    break;
                }
            }else{
                pdaf_tableType = pdaf_tableType_full
            }
        }else{
            pdaf_tableType = pdaf_tableType_full
        }
//        console.debug("pdafTableTypeSetting ", pdaf_tableType)
    }

    // PDAF行列数変更
    // 現在の行列数とアスペクト比とテーブルタイプからレンズ種類を判定する
    function pdafFrameNumSetting(numX, numY){
        var lens = lensType_UNKNOWN
        
// console.debug("pdafFrameNumSetting before", numX, " ", numY)
        var aspect = getImgAspectRatio()
        // 4:3
        if(aspect === aspectRatio_4_3){
            // FULL(L)
            if(pdaf_tableType === pdaf_tableType_full){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_full[lensType_FF][0][aspectRatio_4_3] &&
                       numY === f779_param_table_full[lensType_FF][1][aspectRatio_4_3]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_full[lensType_APS_C][0][aspectRatio_4_3] &&
                             numY === f779_param_table_full[lensType_APS_C][1][aspectRatio_4_3]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_full[lensType_MFTS][0][aspectRatio_4_3] &&
                       numY === f779_param_table_full[lensType_MFTS][1][aspectRatio_4_3]){
                        lens = lensType_MFTS
                    }
                }
            // EX M
            }else if(pdaf_tableType === pdaf_tableType_exM){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exM[lensType_FF][0][aspectRatio_4_3] &&
                       numY === f779_param_table_exM[lensType_FF][1][aspectRatio_4_3]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exM[lensType_APS_C][0][aspectRatio_4_3] &&
                             numY === f779_param_table_exM[lensType_APS_C][1][aspectRatio_4_3]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exM[lensType_MFTS][0][aspectRatio_4_3] &&
                       numY === f779_param_table_exM[lensType_MFTS][1][aspectRatio_4_3]){
                        lens = lensType_MFTS
                    }
                }
            // EX S
            }else if(pdaf_tableType === pdaf_tableType_exS){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exS[lensType_FF][0][aspectRatio_4_3] &&
                       numY === f779_param_table_exS[lensType_FF][1][aspectRatio_4_3]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exS[lensType_APS_C][0][aspectRatio_4_3] &&
                             numY === f779_param_table_exS[lensType_APS_C][1][aspectRatio_4_3]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exS[lensType_MFTS][0][aspectRatio_4_3] &&
                       numY === f779_param_table_exS[lensType_MFTS][1][aspectRatio_4_3]){
                        lens = lensType_MFTS
                    }
                }
            }
        // 3:2
        }else if(aspect === aspectRatio_3_2){
            // FULL
            if(pdaf_tableType === pdaf_tableType_full){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_full[lensType_FF][0][aspectRatio_3_2] &&
                       numY === f779_param_table_full[lensType_FF][1][aspectRatio_3_2]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_full[lensType_APS_C][0][aspectRatio_3_2] &&
                             numY === f779_param_table_full[lensType_APS_C][1][aspectRatio_3_2]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_full[lensType_MFTS][0][aspectRatio_3_2] &&
                       numY === f779_param_table_full[lensType_MFTS][1][aspectRatio_3_2]){
                        lens = lensType_MFTS
                    }
                }
            // EX M
            }else if(pdaf_tableType === pdaf_tableType_exM){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exM[lensType_FF][0][aspectRatio_3_2] &&
                       numY === f779_param_table_exM[lensType_FF][1][aspectRatio_3_2]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exM[lensType_APS_C][0][aspectRatio_3_2] &&
                             numY === f779_param_table_exM[lensType_APS_C][1][aspectRatio_3_2]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exM[lensType_MFTS][0][aspectRatio_3_2] &&
                       numY === f779_param_table_exM[lensType_MFTS][1][aspectRatio_3_2]){
                        lens = lensType_MFTS
                    }
                }
            // EX S
            }else if(pdaf_tableType === pdaf_tableType_exS){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exS[lensType_FF][0][aspectRatio_3_2] &&
                       numY === f779_param_table_exS[lensType_FF][1][aspectRatio_3_2]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exS[lensType_APS_C][0][aspectRatio_3_2] &&
                             numY === f779_param_table_exS[lensType_APS_C][1][aspectRatio_3_2]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exS[lensType_MFTS][0][aspectRatio_3_2] &&
                       numY === f779_param_table_exS[lensType_MFTS][1][aspectRatio_3_2]){
                        lens = lensType_MFTS
                    }
                }
            }
        // 16:9
        }else if(aspect === aspectRatio_16_9){
            // FULL
            if(pdaf_tableType === pdaf_tableType_full){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_full[lensType_FF][0][aspectRatio_16_9] &&
                       numY === f779_param_table_full[lensType_FF][1][aspectRatio_16_9]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_full[lensType_APS_C][0][aspectRatio_16_9] &&
                             numY === f779_param_table_full[lensType_APS_C][1][aspectRatio_16_9]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_full[lensType_MFTS][0][aspectRatio_16_9] &&
                       numY === f779_param_table_full[lensType_MFTS][1][aspectRatio_16_9]){
                        lens = lensType_MFTS
                    }
                }
            // EX M
            }else if(pdaf_tableType === pdaf_tableType_exM){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exM[lensType_FF][0][aspectRatio_16_9] &&
                       numY === f779_param_table_exM[lensType_FF][1][aspectRatio_16_9]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exM[lensType_APS_C][0][aspectRatio_16_9] &&
                             numY === f779_param_table_exM[lensType_APS_C][1][aspectRatio_16_9]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exM[lensType_MFTS][0][aspectRatio_16_9] &&
                       numY === f779_param_table_exM[lensType_MFTS][1][aspectRatio_16_9]){
                        lens = lensType_MFTS
                    }
                }
            // EX S
            }else if(pdaf_tableType === pdaf_tableType_exS){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exS[lensType_FF][0][aspectRatio_16_9] &&
                       numY === f779_param_table_exS[lensType_FF][1][aspectRatio_16_9]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exS[lensType_APS_C][0][aspectRatio_16_9] &&
                             numY === f779_param_table_exS[lensType_APS_C][1][aspectRatio_16_9]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exS[lensType_MFTS][0][aspectRatio_16_9] &&
                       numY === f779_param_table_exS[lensType_MFTS][1][aspectRatio_16_9]){
                        lens = lensType_MFTS
                    }
                }
            }
        // 1:1
        }else if(aspect === aspectRatio_1_1){
            // FULL
            if(pdaf_tableType === pdaf_tableType_full){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_full[lensType_FF][0][aspectRatio_1_1] &&
                       numY === f779_param_table_full[lensType_FF][1][aspectRatio_1_1]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_full[lensType_APS_C][0][aspectRatio_1_1] &&
                             numY === f779_param_table_full[lensType_APS_C][1][aspectRatio_1_1]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_full[lensType_MFTS][0][aspectRatio_1_1] &&
                       numY === f779_param_table_full[lensType_MFTS][1][aspectRatio_1_1]){
                        lens = lensType_MFTS
                    }
                }
            // EX M
            }else if(pdaf_tableType === pdaf_tableType_exM){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exM[lensType_FF][0][aspectRatio_1_1] &&
                       numY === f779_param_table_exM[lensType_FF][1][aspectRatio_1_1]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exM[lensType_APS_C][0][aspectRatio_1_1] &&
                             numY === f779_param_table_exM[lensType_APS_C][1][aspectRatio_1_1]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exM[lensType_MFTS][0][aspectRatio_1_1] &&
                       numY === f779_param_table_exM[lensType_MFTS][1][aspectRatio_1_1]){
                        lens = lensType_MFTS
                    }
                }
            // EX S
            }else if(pdaf_tableType === pdaf_tableType_exS){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exS[lensType_FF][0][aspectRatio_1_1] &&
                       numY === f779_param_table_exS[lensType_FF][1][aspectRatio_1_1]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exS[lensType_APS_C][0][aspectRatio_1_1] &&
                             numY === f779_param_table_exS[lensType_APS_C][1][aspectRatio_1_1]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exS[lensType_MFTS][0][aspectRatio_1_1] &&
                       numY === f779_param_table_exS[lensType_MFTS][1][aspectRatio_1_1]){
                        lens = lensType_MFTS
                    }
                }
            }
        // 17:9
        }else if(aspect === aspectRatio_17_9){
            // FULL
            if(pdaf_tableType === pdaf_tableType_full){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_full[lensType_FF][0][aspectRatio_17_9] &&
                       numY === f779_param_table_full[lensType_FF][1][aspectRatio_17_9]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_full[lensType_APS_C][0][aspectRatio_17_9] &&
                             numY === f779_param_table_full[lensType_APS_C][1][aspectRatio_17_9]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_full[lensType_MFTS][0][aspectRatio_17_9] &&
                       numY === f779_param_table_full[lensType_MFTS][1][aspectRatio_17_9]){
                        lens = lensType_MFTS
                    }
                }
            // EX M
            }else if(pdaf_tableType === pdaf_tableType_exM){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exM[lensType_FF][0][aspectRatio_17_9] &&
                       numY === f779_param_table_exM[lensType_FF][1][aspectRatio_17_9]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exM[lensType_APS_C][0][aspectRatio_17_9] &&
                             numY === f779_param_table_exM[lensType_APS_C][1][aspectRatio_17_9]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exM[lensType_MFTS][0][aspectRatio_17_9] &&
                       numY === f779_param_table_exM[lensType_MFTS][1][aspectRatio_17_9]){
                        lens = lensType_MFTS
                    }
                }
            // EX S
            }else if(pdaf_tableType === pdaf_tableType_exS){
                // センサ:Full
                if(sensorType == sensorType_Full){
                    // FFレンズ
                    if(numX === f779_param_table_exS[lensType_FF][0][aspectRatio_17_9] &&
                       numY === f779_param_table_exS[lensType_FF][1][aspectRatio_17_9]){
                        lens = lensType_FF
                    // APS-Cレンズ
                    }else if(numX === f779_param_table_exS[lensType_APS_C][0][aspectRatio_17_9] &&
                             numY === f779_param_table_exS[lensType_APS_C][1][aspectRatio_17_9]){
                        lens = lensType_APS_C
                    }
                }else{
                    // mFTSレンズ
                    if(numX === f779_param_table_exS[lensType_MFTS][0][aspectRatio_17_9] &&
                       numY === f779_param_table_exS[lensType_MFTS][1][aspectRatio_17_9]){
                        lens = lensType_MFTS
                    }
                }
            }
        }
        if(lensType !== lens){
            lensType = lens
            //レンズが変わればPDAF枠を更新する
            pdaf_frames_update()
 //           console.debug("update")
        }
 //       console.debug("pdafFrameNumSetting after", numX, " ", numY, " ", lens)
    }

    // AF枠の列数を取得する
    function getFrame225SplitNumX() {
        if(dispPDAF) {
            return getFrame779SplitNumX()
        } else if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return getFrame315SplitNumX()
        } else {
            return 15
        }
    }
    function getFrame779SplitNumX() {
        if( lensType === lensType_UNKNOWN){
            return deviceAdapter.af_pdaf_frame_num_X()
        }

        var aspect = getImgAspectRatio()
        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][0][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][0][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][0][aspect]
        }
    }
    function getFrame315SplitNumX() {
        var aspect = getImgAspectRatio()
        return f315_param_table[sensorType][0][aspect]
    }

    // AF枠の行数を取得する
    function getFrame225SplitNumY() {
        if(dispPDAF) {
            return getFrame779SplitNumY()
        } else if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return getFrame315SplitNumY()
        } else {
            return 15
        }
    }
    function getFrame779SplitNumY() {
        if( lensType === lensType_UNKNOWN){
            return deviceAdapter.af_pdaf_frame_num_Y()
        }

        var aspect = getImgAspectRatio()
        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][1][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][1][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][1][aspect]
        }
    }
    function getFrame315SplitNumY() {
        var aspect = getImgAspectRatio()
        return f315_param_table[sensorType][1][aspect]
    }

    // AF枠の基準となる解像度を取得する（X座標）
    function getFrame225ResolutionX() {
        if(dispPDAF) {
            return getFrame779ResolutionX()
        } else if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return getFrame315ResolutionX()
        } else {
            return 720
        }
    }
    function getFrame779ResolutionX() {
        var aspect = getImgAspectRatio()
        if( lensType === lensType_UNKNOWN){
            //領域はレンズ差とかないのでFFのを使う
            return f779_param_table_full[lensType_FF][2][aspect]
        }

        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][2][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][2][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][2][aspect]
        }
    }
    function getFrame315ResolutionX() {
        var aspect = getImgAspectRatio()
        return f315_param_table[sensorType][2][aspect]
    }

    // AF枠の基準となる解像度を取得する（Y座標）
    function getFrame225ResolutionY() {
        if(dispPDAF) {
            return getFrame779ResolutionY()
        } else if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return getFrame315ResolutionY()
        } else {
            return 480
        }
    }
    function getFrame779ResolutionY() {
        var aspect = getImgAspectRatio()
        if( lensType === lensType_UNKNOWN){
            //領域はレンズ差とかないのでFFのを使う
            return f779_param_table_full[lensType_FF][3][aspect]
        }

        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][3][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][3][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][3][aspect]
        }
    }
    function getFrame315ResolutionY() {
        var aspect = getImgAspectRatio()
        return f315_param_table[sensorType][3][aspect]
    }

    // AF枠設定範囲のマージンを取得する（左右）
    function getFrame225MarginH() {
        if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return getFrame315MarginH()
        } else {
            return 60
        }
    }
    function getFrame315MarginH() {
        var aspect = getImgAspectRatio()
        return f315_param_table[sensorType][4][aspect]
    }

    // AF枠設定範囲のマージンを取得する（上下）
    function getFrame225MarginV() {
        if(deviceAdapter.afFramesMax === LT.Utilities.AFFMax_315) {
            return getFrame315MarginV()
        } else {
            return 40
        }
    }
    function getFrame315MarginV() {
        var aspect = getImgAspectRatio()
        return f315_param_table[sensorType][5][aspect]
    }

    // PDAF枠 中心点距離(X)
    function getFrame779FrameIntervalX() {
        var aspect = getImgAspectRatio()
        if( lensType === lensType_UNKNOWN){
            //領域はレンズ差とかないのでFFのを使う
            //return parseInt((f779_param_table_full[lensType_FF][2][aspect]*0.9)/deviceAdapter.af_pdaf_frame_num_X())
            return deviceAdapter.af_pdaf_cluster_x(f779_param_table_full[lensType_FF][2][aspect])
        }

        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][4][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][4][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][4][aspect]
        }
    }
    // PDAF枠 中心点距離(Y)
    function getFrame779FrameIntervalY() {
        var aspect = getImgAspectRatio()
        if( lensType === lensType_UNKNOWN){
            //領域はレンズ差とかないのでFFのを使う
            //return parseInt((f779_param_table_full[lensType_FF][3][aspect]*0.9)/deviceAdapter.af_pdaf_frame_num_Y())
            return deviceAdapter.af_pdaf_cluster_y(f779_param_table_full[lensType_FF][3][aspect])
        }

        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][5][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][5][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][5][aspect]
        }
    }
    // PDAF枠 緑枠サイズ(幅)
    function getFrame779FrameSizeH() {
        var aspect = getImgAspectRatio()
        if( lensType === lensType_UNKNOWN){
            //領域はレンズ差とかないのでFFのを使う
            //return parseInt((f779_param_table_full[lensType_FF][2][aspect]*0.9)/deviceAdapter.af_pdaf_frame_num_X()*0.66)
            return deviceAdapter.af_pdaf_frame_size_w(f779_param_table_full[lensType_FF][2][aspect], f779_param_table_full[lensType_FF][3][aspect])
        }

        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][6][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][6][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][6][aspect]
        }
    }
    // PDAF枠 緑枠サイズ(高さ)
    function getFrame779FrameSizeV() {
        var aspect = getImgAspectRatio()
        if( lensType === lensType_UNKNOWN){
            //領域はレンズ差とかないのでFFのを使う
            //枠は正方形にしておく
            //return parseInt((f779_param_table_full[lensType_FF][2][aspect]*0.9)/deviceAdapter.af_pdaf_frame_num_X()*0.66)
            return deviceAdapter.af_pdaf_frame_size_h(f779_param_table_full[lensType_FF][2][aspect], f779_param_table_full[lensType_FF][3][aspect])
        }

        switch(pdaf_tableType){
        case pdaf_tableType_full:
            return f779_param_table_full[lensType][7][aspect]
        case pdaf_tableType_exM:
            return f779_param_table_exM[lensType][7][aspect]
        case pdaf_tableType_exS:
            return f779_param_table_exS[lensType][7][aspect]
        }
    }

    Component.onCompleted: {
        //mode_label.text = afmode[mode].name
        dispFrame()
    }

    MouseArea {
        id: frameMsArea
        anchors.fill: parent

        property real dragPosX: 0
        property real dragPosY: 0

        onPositionChanged:(mouse)=> {//(MouseEvent mouse)
            //LTSubFunction.console_debug.out("onPositionChanged mode="+mode+" mfa="+deviceAdapter.mfa_mode+" mfassist="+deviceAdapter.mfAssistMode)
            var x_conv = (mouse.x * 1000) / afframe.width
            var y_conv = (mouse.y * 1000) / afframe.height
            if(root.pinpoint_drag_flg) {
                // 動画LV拡大 Zoom
                if (mode == afmode_lvmag_z) {
                    var mg = parseInt(deviceAdapter.lvMag_magnify / 10)
                    var X1 = root.mf_X0 - parseInt(((mouse.x - root.mf_x0) * 1000) / (afframe.width * mg))
                    var Y1 = root.mf_Y0 - parseInt(((mouse.y - root.mf_y0) * 1000) / (afframe.height * mg))
                    deviceAdapter.lvMag_pos_X = X1
                    deviceAdapter.lvMag_pos_Y = Y1
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MOVE_REQ()
                }
                // 動画LV拡大 PinP
                else if (mode == afmode_lvmag_p) {
                    deviceAdapter.lvMag_pos_X = x_conv
                    deviceAdapter.lvMag_pos_Y = y_conv
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MOVE_REQ()
                }
                else if(mode == afmode_pinpointf) {
                    // TODO: USBTHRC110-31
//                    var ppFrameW = deviceAdapter.af_pinpoin_frame_width() * root.width / 1000
//                    var ppFrameH = deviceAdapter.af_pinpoin_frame_area_height() * root.height / 1000

//                    if (mouse.x < ppFrameW/2
//                        || mouse.x > root.width - ppFrameW/2
//                        || mouse.y < ppFrameH/2
//                        || mouse.y > root.height - ppFrameH/2) {
//                        return
//                    }

//                    dragPosX = mouse.x
//                    dragPosY = mouse.y

                    if (x_conv < frame_drag.minDragX) {
                        x_conv = frame_drag.minDragX
                    }
                    if (x_conv > frame_drag.maxDragX) {
                        x_conv = frame_drag.maxDragX
                    }
                    if (y_conv < frame_drag.minDragY) {
                        y_conv = frame_drag.minDragY
                    }
                    if (y_conv > frame_drag.maxDragY) {
                        y_conv = frame_drag.maxDragY
                    }

                    // ピンポイント設定APIを呼ぶ
                    deviceAdapter.afFrame_pos_pin_X = x_conv
                    deviceAdapter.afFrame_pos_pin_Y = y_conv
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_MOVE_POS()
                }
                else if(mode == afmode_mff) {
                    // TODO: USBTHRC110-31
//                    if (mouse.x < 0 || mouse.x > root.width
//                        || mouse.y < 0 || mouse.y > root.height) {
//                        return
//                    }
/*                    if (x_conv < frame_drag.minDragX) {
                        x_conv = frame_drag.minDragX
                    }
                    if (x_conv > frame_drag.maxDragX) {
                        x_conv = frame_drag.maxDragX
                    }
                    if (y_conv < frame_drag.minDragY) {
                        y_conv = frame_drag.minDragY
                    }
                    if (y_conv > frame_drag.maxDragY) {
                        y_conv = frame_drag.maxDragY
                    }
*/
                    //カメラから取得される情報を信じると隙間ができる？
                    if( x_conv<0){
                        x_conv=0
                    }
                    if( x_conv>999){
                        x_conv=999
                    }
                    if( y_conv<0){
                        y_conv = 0;
                    }
                    if( y_conv>999){
                        y_conv = 999;
                    }
                    // MF設定APIを呼ぶ
                    deviceAdapter.mfFrame_pos_X = x_conv
                    deviceAdapter.mfFrame_pos_Y = y_conv
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
                }
                else if(mode == afmode_pinpointz) {
                    //var m = parseInt(deviceAdapter.af_magnify / 10)
                    //var x_delta = parseInt(mouse.x - afframe.width/2)
                    //var y_delta = parseInt(mouse.y - afframe.height/2)
                    //var x_conv1 = root.mf_pos_x + parseInt( (x_delta * 1000) / afframe.width )
                    //var y_conv1 = root.mf_pos_y + parseInt( (y_delta * 1000) / afframe.height )
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    deviceAdapter.afFrame_pos_pin_X = x_conv//1
                    deviceAdapter.afFrame_pos_pin_Y = y_conv//1
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
                    LTSubFunction.console_debug.out("onPositionChanged x="+x_conv+" y="+y_conv)
                }
                else if ((mode == afmode_mfz) ||
                         ((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_normal))) {
                    //拡大率=mのときの画像サイズを1000x1000と正規化したときの表示したい中心座標値を設定する。
                    //X1 = X0 - (x1 – x0) * 1000 / w / m
                    //Y1 = Y0 – (y1 - y0)  * 1000 / h / m
                    //(このX1値, Y1値を設定)
                    var x = deviceAdapter.af_pinpoin_frame_pos_X()
                    var y = deviceAdapter.af_pinpoin_frame_pos_Y()
                    var cx = deviceAdapter.af_pinpoin_frame_cursorX()
                    var cy = deviceAdapter.af_pinpoin_frame_cursorY()
                    var aw = deviceAdapter.af_pinpoin_frame_area_width()
                    var ah = deviceAdapter.af_pinpoin_frame_area_height()
                    var mg = parseInt(deviceAdapter.mf_magnify / 10)
                    //var X1 = cx + parseInt((parseInt(mouse.x) - root.width/2) / mg);
                    //var Y1 = cy + parseInt((parseInt(mouse.y) - root.height/2) / mg);
                    var X1 = root.mf_X0 - parseInt(((mouse.x - root.mf_x0) * 1000) / (afframe.width * mg))
                    var Y1 = root.mf_Y0 - parseInt(((mouse.y - root.mf_y0) * 1000) / (afframe.height * mg))
                    // MF設定APIを呼ぶ
                    deviceAdapter.mfFrame_pos_X = X1
                    deviceAdapter.mfFrame_pos_Y = Y1
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
                    //afframe.changeValueMfz(x + (X1 - root.mf_X0), y + (Y1 - root.mf_Y0))
                    //afframe.mfAssistZoomSetting(x + (X1 - root.mf_X0), y + (Y1 - root.mf_Y0),parseInt(afframe.width/mg),parseInt(afframe.height/mg))
                    LTSubFunction.console_debug.out("onPositionChanged x0="+root.mf_x0+" y0="+root.mf_y0+" X0="+root.mf_X0+" Y0="+root.mf_Y0+" x1="+mouse.x+" y1="+mouse.y+" X1="+X1+" Y1="+Y1)
                }
                else if(mode == afmode_pinpointp) {
                    //var x_rev = parseInt((root.mf_pos_x * afframe.width) / 1000)
                    //var y_rev = parseInt((root.mf_pos_y * afframe.height) / 1000)
                    //var x_conv = root.mf_pos_x - parseInt(((mouse.x - x_rev) * 1000) / (afframe.width * afFrame_magnification))
                    //var y_conv = root.mf_pos_y - parseInt(((mouse.y - y_rev) * 1000) / (afframe.height * afFrame_magnification))
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    //// PinpointAF設定APIを呼ぶ
                    //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_PinPoint_Frame(x_conv, y_conv);
                    var ctx = deviceAdapter.af_pinpoin_frame_centerX()
                    var cty = deviceAdapter.af_pinpoin_frame_centerY()
                    var aw = deviceAdapter.af_pinpoin_frame_area_width()
                    var ah = deviceAdapter.af_pinpoin_frame_area_height()
                    var x1 = ctx - parseInt(aw/2)
                    var y1 = cty - parseInt(ah/2)
                    var cx = x_conv
                    var cy = y_conv
                    var x0 = Math.min(Math.max(0, parseInt(((cx-x1)*1000)/aw)), 1000 )
                    var y0 = Math.min(Math.max(0, parseInt(((cy-y1)*1000)/ah)), 1000 )
                    deviceAdapter.afFrame_pos_pin_X = x0
                    deviceAdapter.afFrame_pos_pin_Y = y0
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
                }
                else if ((mode == afmode_mfp) ||
                         ((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_pinp))) {
                    //var x_rev = parseInt((root.mf_pos_x * afframe.width) / 1000)
                    //var y_rev = parseInt((root.mf_pos_y * afframe.height) / 1000)

                    //var x_conv = root.mf_pos_x - parseInt(((mouse.x - x_rev) * 1000) / (afframe.width * afFrame_magnification))
                    //var y_conv = root.mf_pos_y - parseInt(((mouse.y - y_rev) * 1000) / (afframe.height * afFrame_magnification))
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    // PinpointAF設定APIを呼ぶ
                    //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_PinPoint_Frame(x_conv, y_conv);
                    deviceAdapter.mfFrame_pos_X = x_conv
                    deviceAdapter.mfFrame_pos_Y = y_conv
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
                }
            }
        }
        onPressed:(mouse)=> {//(MouseEvent mouse)
// IVC >> Ver.1.9 >> start >> [THRBOXV100-126]
            if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                return
            }
// IVC << Ver.1.9 << end << [THRBOXV100-126]
            LTSubFunction.console_debug.out("onPressed mode="+mode+" mfa="+deviceAdapter.mfa_mode+" mfassist="+deviceAdapter.mfAssistMode)
            var x_conv = parseInt( (mouse.x * 1000) / afframe.width )
            var y_conv = parseInt( (mouse.y * 1000) / afframe.height )
            var ret1 = LT.DeviceAdapter.Ternary_False
            // 動画LV拡大 Zoom
            if (mode == afmode_lvmag_z) {
                root.pinpoint_drag_flg = true
                var x = deviceAdapter.af_pinpoin_frame_pos_X()
                var y = deviceAdapter.af_pinpoin_frame_pos_Y()
                var mg = parseInt(deviceAdapter.lvMag_magnify / 10)
                root.mf_x0 = parseInt(mouse.x)
                root.mf_y0 = parseInt(mouse.y)
                if((root.mf_X0 != -1) && (root.mf_Y0 != -1)) {
                    root.mf_X0 = deviceAdapter.lvMag_pos_X
                    root.mf_Y0 = deviceAdapter.lvMag_pos_Y
                } else {
                    root.mf_X0 = x + parseInt((root.mf_x0 - afframe.width/2) / mg);
                    root.mf_Y0 = y + parseInt((root.mf_y0 - afframe.height/2) / mg);
                }
            }
            // 動画LV拡大 PinP
            else if (mode == afmode_lvmag_p) {
                root.pinpoint_drag_flg = true
                deviceAdapter.lvMag_pos_X = x_conv
                deviceAdapter.lvMag_pos_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MOVE_REQ()
            }
            else if((!afaeStartFlg)&&(mode == afmode_pinpoint)) {
                //root.center_x = x_conv;//parseInt(mouse.x)
                //root.center_y = y_conv;//parseInt(mouse.y)
                // ピンポイント設定APIを呼ぶ
                deviceAdapter.afFrame_pos_pin_X = x_conv
                deviceAdapter.afFrame_pos_pin_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_AF_START()
                root.pinpoint_drag_flg = true
            }
            if((!afaeStartFlg)&&(mode == afmode_pinpointf)) {
                // カメラ側でMFアシスト移動モード状態
                root.pinpoint_drag_flg = true
            }
            else if( (mode == afmode_mf) ){
                root.pinpoint_drag_flg = true
                //root.center_x = x_conv;//parseInt(mouse.x)
                //root.center_y = y_conv;//parseInt(mouse.y)
                // MF設定APIを呼ぶ
                deviceAdapter.mfFrame_pos_X = x_conv
                deviceAdapter.mfFrame_pos_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_START_REQ(LT.Utilities.RcMfaMode_Move)
            }
            else if( (mode == afmode_mff) ){
                // カメラ側でMFアシスト移動モード状態
                root.pinpoint_drag_flg = true
            }
            else if((!afaeStartFlg)&&(mode == afmode_pinpointz)) {
                root.pinpoint_drag_flg = true
                //var m = parseInt(deviceAdapter.af_magnify / 10)
                //var x_delta = parseInt(mouse.x - afframe.width/2)
                //var y_delta = parseInt(mouse.y - afframe.height/2)
                //var x_conv1 = root.mf_pos_x + parseInt( (x_delta * 1000) / afframe.width )
                //var y_conv1 = root.mf_pos_y + parseInt( (y_delta * 1000) / afframe.height )
                deviceAdapter.afFrame_pos_pin_X = x_conv//1
                deviceAdapter.afFrame_pos_pin_Y = y_conv//1
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
                LTSubFunction.console_debug.out("onPressed x="+x_conv+" y="+y_conv)
            }
            else if ((mode == afmode_mfz) ||
                     ((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_normal))) {
                root.pinpoint_drag_flg = true
                var x = deviceAdapter.af_pinpoin_frame_pos_X()
                var y = deviceAdapter.af_pinpoin_frame_pos_Y()
                var cx = deviceAdapter.af_pinpoin_frame_cursorX()
                var cy = deviceAdapter.af_pinpoin_frame_cursorY()
                var aw = deviceAdapter.af_pinpoin_frame_area_width()
                var ah = deviceAdapter.af_pinpoin_frame_area_height()
                var ctx = deviceAdapter.af_pinpoin_frame_centerX()
                var cty = deviceAdapter.af_pinpoin_frame_centerX()
                var mg = parseInt(deviceAdapter.mf_magnify / 10)
                root.mf_x0 = parseInt(mouse.x)
                root.mf_y0 = parseInt(mouse.y)
                if((root.mf_X0 != -1) && (root.mf_Y0 != -1)) {
                    root.mf_X0 = deviceAdapter.mfFrame_pos_X
                    root.mf_Y0 = deviceAdapter.mfFrame_pos_Y
                } else {
                    root.mf_X0 = x + parseInt((root.mf_x0 - afframe.width/2) / mg);
                    root.mf_Y0 = y + parseInt((root.mf_y0 - afframe.height/2) / mg);
                }

                LTSubFunction.console_debug.out("onPressed x="+x+" y="+y+" cx="+cx+" cy="+cy+" ctx="+ctx+" cty="+cty+" x0="+root.mf_x0+" y0="+root.mf_y0+" X0="+root.mf_X0+" Y0="+root.mf_Y0)
            }
            else if((!afaeStartFlg)&&(mode == afmode_pinpointp)) {
                root.pinpoint_drag_flg = true
                //root.center_x = x_conv;//parseInt(mouse.x)
                //root.center_y = y_conv;//parseInt(mouse.y)
                //root.mf_pos_x = x_conv
                //root.mf_pos_y = y_conv
                //deviceAdapter.afFrame_pos_pin_X = x_conv
                //deviceAdapter.afFrame_pos_pin_Y = y_conv
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
                //３．changeValuePinpoint内での計算
                //  afmode_pinpointpの場合、PinP内にx,yを変換する必要があります。
                //  こちらで確認している計算式は下記のようになっています。
                // x1 = FocusAssist_Pos.pos_x - (FocusAssist_Size.pos_x / 2),
                // y1 = FocusAssist_Pos.pos_y - (FocusAssist_Size.pos_y / 2),
                // x2 = FocusAssist_Pos.pos_x + ((FocusAssist_Size.pos_x + 1) / 2),
                // y2 = FocusAssist_Pos.pos_y + ((FocusAssist_Size.pos_y + 1) / 2),
                // cx = x1 + PinPointAfMagPosX * (x2 - x1) / 1000;
                // cy = y1 + PinPointAfMagPosY * (y2 - y1) / 1000;
                var ctx = deviceAdapter.af_pinpoin_frame_centerX()
                var cty = deviceAdapter.af_pinpoin_frame_centerY()
                var aw = deviceAdapter.af_pinpoin_frame_area_width()
                var ah = deviceAdapter.af_pinpoin_frame_area_height()
                var x1 = ctx - parseInt(aw/2)
                var y1 = cty - parseInt(ah/2)
                var cx = x_conv
                var cy = y_conv
                var x0 = Math.min(Math.max(0, parseInt(((cx-x1)*1000)/aw)), 1000 )
                var y0 = Math.min(Math.max(0, parseInt(((cy-y1)*1000)/ah)), 1000 )
                deviceAdapter.afFrame_pos_pin_X = x0
                deviceAdapter.afFrame_pos_pin_Y = y0
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
                LTSubFunction.console_debug.out("onPressed ctx="+ctx+" cty="+cty+" aw="+aw+" ah="+ah+" x1="+x1+" y1="+y1+" cx="+cx+" cy="+cy+" x0="+x0+" y0="+y0)
            }
            else if ((mode == afmode_mfp) ||
                     ((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_pinp))) {
                root.pinpoint_drag_flg = true
                //root.center_x = x_conv;//parseInt(mouse.x)
                //root.center_y = y_conv;//parseInt(mouse.y)
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_PinPoint_Frame(x_conv, y_conv);
                deviceAdapter.mfFrame_pos_X = x_conv
                deviceAdapter.mfFrame_pos_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
            }
        }
        onReleased:(mouse)=> {//(MouseEvent mouse)
// IVC >> Ver.1.9 >> start >> [THRBOXV100-126]
            if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                return
            }
// IVC << Ver.1.9 << end << [THRBOXV100-126]
            LTSubFunction.console_debug.out("onReleased mode="+mode+" mfa="+deviceAdapter.mfa_mode+" mfassist="+deviceAdapter.mfAssistMode)
            var x_conv = parseInt( (mouse.x * 1000) / afframe.width )
            var y_conv = parseInt( (mouse.y * 1000) / afframe.height )
            //レンジ外の値がカメラに伝わると誤作動する？
            if( x_conv<0){
                x_conv=0
            }
            if( x_conv>999){
                x_conv=999
            }
            if( y_conv<0){
                y_conv = 0;
            }
            if( y_conv>999){
                y_conv = 999;
            }

            var ret1 = LT.DeviceAdapter.Ternary_False
            root.pinpoint_drag_flg = false
            // 動画LV拡大 Zoom
            if (mode == afmode_lvmag_z) {
                var m = parseInt(deviceAdapter.lvMag_magnify / 10)
                var x_delta = parseInt(mouse.x - afframe.width/2)
                var y_delta = parseInt(mouse.y - afframe.height/2)
                var X1 = root.mf_X0 - parseInt(((mouse.x - root.mf_x0) * 1000) / (afframe.width * m))
                var Y1 = root.mf_Y0 - parseInt(((mouse.y - root.mf_y0) * 1000) / (afframe.height * m))
                if((root.mf_X0 != X1)&&(root.mf_Y0 != Y1)) {
                    deviceAdapter.lvMag_pos_X = X1
                    deviceAdapter.lvMag_pos_Y = Y1
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MOVE_REQ()
                }
            }
            // 動画LV拡大 PinP
            else if(mode == afmode_lvmag_p) {
                deviceAdapter.lvMag_pos_X = x_conv
                deviceAdapter.lvMag_pos_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MOVE_REQ()
            }
            else if((!afaeStartFlg)&&((mode == afmode_pinpointf) ||
                                 (mode == afmode_pinpoint))) {  // クリック時はafmode_pinpointfになる前にonReleased発生するため
                //root.center_x = x_conv;//parseInt(mouse.x)
                //root.center_y = y_conv;//parseInt(mouse.y)
                deviceAdapter.afFrame_pos_pin_X = x_conv
                deviceAdapter.afFrame_pos_pin_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMSTART();
            }else if((mode == afmode_mff) ||
                     (mode == afmode_mf)){    // クリック時はafmode_mffになる前にonReleased発生するため
                //root.center_x = x_conv;//parseInt(mouse.x)
                //root.center_y = y_conv;//parseInt(mouse.y)
                // MF設定APIを呼ぶ
                deviceAdapter.mfFrame_pos_X = x_conv
                deviceAdapter.mfFrame_pos_Y = y_conv
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_END_REQ()
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_ONEPOINT_REQ()
            }
            else if((!afaeStartFlg)&&(mode == afmode_pinpointz)) {
                //var m = parseInt(deviceAdapter.af_magnify / 10)
                //var x_delta = parseInt(mouse.x - afframe.width/2)
                //var y_delta = parseInt(mouse.y - afframe.height/2)
                //var x_conv1 = root.mf_pos_x + parseInt( (x_delta * 1000) / afframe.width )
                //var y_conv1 = root.mf_pos_y + parseInt( (y_delta * 1000) / afframe.height )
                //root.mf_pos_x = x_conv1
                //root.mf_pos_y = y_conv1
                //if((deviceAdapter.afFrame_pos_pin_X != x_conv1)&&(deviceAdapter.afFrame_pos_pin_Y != y_conv1)) {
                if((deviceAdapter.afFrame_pos_pin_X != x_conv)&&(deviceAdapter.afFrame_pos_pin_Y != y_conv)) {
                    deviceAdapter.afFrame_pos_pin_X = x_conv//1
                    deviceAdapter.afFrame_pos_pin_Y = y_conv//1
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
//                    LTSubFunction.console_debug.out("onReleased m="+m+" dx="+x_delta+" dy="+y_delta+" x1="+x_conv1+" y1="+y_conv1)
                }
            }
            else if ((mode == afmode_mfz) ||
                     ((afaeStartFlg)&&(mfzoom_mode == mfzoom_mode_normal))) {
                //拡大率=mのときの画像サイズを1000x1000と正規化したときの表示したい中心座標値を設定する。
                //X1 = X0 - (x1 – x0) * 1000 / w / m
                //Y1 = Y0 – (y1 - y0)  * 1000 / h / m
                //(このX1値, Y1値を設定)
                var m = parseInt(deviceAdapter.mf_magnify / 10)
                var x_delta = parseInt(mouse.x - afframe.width/2)
                var y_delta = parseInt(mouse.y - afframe.height/2)
                var X1 = root.mf_X0 - parseInt(((mouse.x - root.mf_x0) * 1000) / (afframe.width * m))
                var Y1 = root.mf_Y0 - parseInt(((mouse.y - root.mf_y0) * 1000) / (afframe.height * m))
                if((root.mf_X0 != X1)&&(root.mf_Y0 != Y1)) {
                    // MF設定APIを呼ぶ
                    deviceAdapter.mfFrame_pos_X = X1
                    deviceAdapter.mfFrame_pos_Y = Y1
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_MOVE_REQ()
                    LTSubFunction.console_debug.out("onReleased x0="+root.mf_x0+" y0="+root.mf_y0+" X0="+root.mf_X0+" Y0="+root.mf_Y0+" x1="+mouse.x+" y1="+mouse.y+" X1="+X1+" Y1="+Y1)
                }
            }
        }
        onClicked:(mouse)=> {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-126]
            if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                return
            }
// IVC << Ver.1.9 << end << [THRBOXV100-126]
            LTSubFunction.console_debug.out("onClicked mode="+mode)
            var x_conv = parseInt( (mouse.x * 1000) / afframe.width )
            var y_conv = parseInt( (mouse.y * 1000) / afframe.height )
            var ret1 = LT.DeviceAdapter.Ternary_False
            var ret2 = LT.DeviceAdapter.Ternary_True
            var ret3 = LT.DeviceAdapter.Ternary_True

            //if((!afaeStartFlg)||(mfzoom_mode==mfzoom_mode_unknown)) {
                LTSubFunction.console_debug.out("onClicked position change")
                switch(mode) {
                case afmode_pointone://      0
                // ivc >> start >> No.3 -> nakhuong
                case afmode_pointone_aux:
                // ivc << end << No.3 -> nakuong
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    // １点設定APIを呼ぶ
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_1POINT_AF(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    break;
                case afmode_point225:
                case afmode_point225s:
                case afmode_point225_af:
                case afmode_point225s_af:
                case afmode_point225f:
                case afmode_point225sf:
                case afmode_point225f_af:
                case afmode_point225sf_af:
                case afmode_face_225:
                case afmode_face_225_af:
                case afmode_face_225f:
                case afmode_face_225f_af:
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    break;
                case afmode_face://          3
                case afmode_face_eye://      4
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    if(deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) {
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_START(x_conv, y_conv);
                    } else {
                        // 顔設定APIを呼ぶ
                        //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_1POINT_AF(x_conv, y_conv);
                        ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                        ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                        ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                        if((ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                            // モードをafmode_face_afに変える
                            changeMode(afmode_face_af)
                        }
                    }
                    break;
                case afmode_face_af://       5
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    // 顔設定APIを呼ぶ
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_1POINT_AF(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    break;
                case afmode_chase://         6
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    // 追尾設定APIを呼ぶ
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_1POINT_AF(x_conv, y_conv);
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    if(deviceAdapter.af_onepoin_frame_val() == LT.Utilities.AFFrameSimpleState_On) {
                        ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                        ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                        ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                        if((ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                            // モードをafmode_chase_afに変える
                            changeMode(afmode_chase_af)
                        }
                    } else {
                        ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_START(x_conv, y_conv);
                        if(ret1==LT.DeviceAdapter.Ternary_True){
                            // モードをafmode_chase_afに変える
                            changeMode(afmode_chase_af)
                        }
                    }
                    break;
                case afmode_chase_af://      7
                    //root.center_x = x_conv;//parseInt(mouse.x)
                    //root.center_y = y_conv;//parseInt(mouse.y)
                    // 追尾設定APIを呼ぶ
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_1POINT_AF(x_conv, y_conv);
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_STOP();
                    if(deviceAdapter.af_onepoin_frame_val() == LT.Utilities.AFFrameSimpleState_On) {
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    } else {
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_START(x_conv, y_conv);
                    }
                    break;
                case afmode_pinpoint:
                    if(deviceAdapter.af_onepoin_frame_val() == LT.Utilities.AFFrameSimpleState_On) {
                        ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                        ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                        ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    }
                    break;
                case afmode_pinpointf:
                    break;
                case afmode_pinpointz:
                    // 全画面の場合、マウスドラッグでの移動のためここではなにもしない。
                    break;
                case afmode_pinpointp:
                    // PinPの場合、マウスクリックで拡大位置選択
                    //root.mf_pos_x = x_conv
                    //root.mf_pos_y = y_conv
                    //deviceAdapter.afFrame_pos_pin_X = x_conv
                    //deviceAdapter.afFrame_pos_pin_Y = y_conv
                    //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMMOVE()
                    break;
                case afmode_mf:
                    break;
                case afmode_mff:
                    break;
                case afmode_mfz:
                case afmode_mfp:
                    break;
                case afmode_custom:
                case afmode_customs:
                case afmode_custom_af:
                case afmode_customs_af:
                case afmode_customf:
                case afmode_customsf:
                case afmode_customf_af:
                case afmode_customsf_af:
                case afmode_customo:
                case afmode_customo_af:
                case afmode_customof:
                case afmode_customof_af:
                    // ここでは何もしない
                    break;
                default:
                    // ここでは何もしない
                    break;
                }
            //}
        }
        onDoubleClicked: {
            // ダブルクリックすると、doubleClickedを受信しないと、clickedが2回発生する。
            // doubleClicked受信すると、clicked->doubleClickedになる。
        }
    }

    // frame_one
    LTAFFrameSquare {
        id: center_rect
        x: {
            //測光スポット時に十字表示に引きずられて中央表示なってしまう
            //AF枠で強制中央表示するモードは無さそうなのでcenter_keepは無視するように変更
            /*
            if(root.center_keep) {
                parseInt(500 * afframe.width / 1000) - parseInt(center_rect.width / 2)
            } else {
                parseInt(root.center_x * afframe.width / 1000) - parseInt(center_rect.width / 2)
            }
            */
            parseInt(root.center_x * afframe.width / 1000) - parseInt(center_rect.width / 2)
          }
        y: {
            //測光スポット時に十字表示に引きずられて中央表示なってしまう
            //AF枠で強制中央表示するモードは無さそうなのでcenter_keepは無視するように変更
            /*
            if(root.center_keep) {
                parseInt(500 * afframe.height / 1000) - parseInt(center_rect.height / 2)
            } else {
                parseInt(root.center_y * afframe.height / 1000) - parseInt(center_rect.height / 2)
            }
            */
            parseInt(root.center_y * afframe.height / 1000) - parseInt(center_rect.height / 2)
        }

        width: parseInt(root.center_width * afframe.width / 1000)
        height: parseInt(root.center_height * afframe.height / 1000)
        visible: false
        afframe_width: afframe.width
        afframe_height: afframe.height
    }

    // ivc >> start >> No.3 -> nakhuong
    LTAFFrameSquare {
        //四角枠の外側の半透明の枠
        id: center_aux_rect
        x: {
            //測光スポット時に十字表示に引きずられて中央表示なってしまう
            //AF枠で強制中央表示するモードは無さそうなのでcenter_keepは無視するように変更
            /*
            if(root.center_keep) {
                parseInt(500 * afframe.width / 1000) - parseInt(center_rect.width)
            } else {
                parseInt(root.center_x * afframe.width / 1000) - parseInt(center_rect.width)
            }
            */
            parseInt(root.center_x * afframe.width / 1000) - parseInt(center_rect.width)
          }
        y: {
            //測光スポット時に十字表示に引きずられて中央表示なってしまう
            //AF枠で強制中央表示するモードは無さそうなのでcenter_keepは無視するように変更
            /*
            if(root.center_keep) {
                parseInt(500 * afframe.height / 1000) - parseInt(center_rect.height)
            } else {
                parseInt(root.center_y * afframe.height / 1000) - parseInt(center_rect.height)
            }
            */
            parseInt(root.center_y * afframe.height / 1000) - parseInt(center_rect.height)
        }

        width: 2 * parseInt(root.center_width * afframe.width / 1000)
        height: 2 * parseInt(root.center_height * afframe.height / 1000)
        opacity: 0.5
        visible: false
        sq_mode: afmode_sq_normal_white
    }
    // ivc << end << No.3 -> nakhuong

    //frame_face
    //LTAFFrameSquare {
    //    id: face_rect
    //    x: parseInt(root.face_detect_x * afframe.width / 1000) - parseInt(root.face_detect_width * afframe.width / 2000)
    //    y: parseInt(root.face_detect_y * afframe.height / 1000) - parseInt(root.face_detect_height * afframe.height / 2000)
    //    width: parseInt(root.face_detect_width * afframe.width / 1000)
    //    height: parseInt(root.face_detect_height * afframe.height / 1000)
    //    visible: false
    //}

    // face rect
    Item {
        id: face_rect
        visible: true
        property var face_Frame: new Array
        property var face_detect_s: new Array
        property var face_detect_x: new Array
        property var face_detect_y: new Array
        property var face_detect_w: new Array
        property var face_detect_h: new Array
        property int parent_width: root.width
        property int parent_height: root.height
        function changeMode(arg) {
            //LTSubFunction.console_debug.out("changeMode arg = " + arg);
            var frames = face_Frame
            for (var i=0; i<frames.length; i++) {
                frames[i].changeMode(arg)
            }
            face_Frame = frames
        }
        function changeVisible(arg) {
            //LTSubFunction.console_debug.out("changeVisible arg = " + arg);
            face_rect.visible = arg
            var frames = face_Frame
            if(arg) {
                for (var i=0; i<frames.length; i++) {
                    if((face_detect_s[i])&&(face_detect_w[i] * face_detect_h[i])) {
                        frames[i].visible = true
                    } else {
                        frames[i].visible = false
                    }
                }
            } else {
                for (var i=0; i<15; i++) {
                    face_detect_w[i] = 0
                    face_detect_h[i] = 0
                }
                for (var i=0; i<frames.length; i++) {
                    frames[i].visible = false
                }
            }
            face_Frame = frames
        }
        onParent_heightChanged: {
            changeAllValue()
        }
        onParent_widthChanged: {
            changeAllValue()
        }

        function changeAllValue() {
            for(var i = 0; i < 15; i ++ ) {
                var s = face_detect_s[i]
                var x = face_detect_x[i]
                var y = face_detect_y[i]
                var w = face_detect_w[i]
                var h = face_detect_h[i]

                changeFrame(i, s, x, y, w, h)
            }
        }

        function changeValue(index, status, s, f, v, x, y, w, h) {
            face_detect_s[index] = status
            face_detect_x[index] = x
            face_detect_y[index] = y
            face_detect_w[index] = w
            face_detect_h[index] = h

            changeFrame(index, status, s, f, v, x, y, w, h)
        }

        function changeFrame(index, status, s, f, v, x, y, w, h) {
            //LTSubFunction.console_debug.out("changeValue index=" + index + " status=" + status + " s=" + s + " f=" + f + " v=" + v +" x=" + x + " y=" + y + " w=" + w + " h=" + h)
            if ((0 <= index)&&(index < 15)) {
                var frames = face_Frame
                if(frames.length <= index) {
                    return
                }
                if(status == 2) {
                    //AF情報：顔検出ステータス：重要顔
                    //LTSubFunction.console_debug.out("changeValue2 index=" + index + " status=" + status + " x=" + x + " y=" + y + " w=" + w + " h=" + h)
                    frames[index].width = parseInt(w * face_rect.parent_width / 1000)
                    frames[index].height = parseInt(h * face_rect.parent_height / 1000)
                    frames[index].x = parseInt(x * root.width / 1000) - parseInt(w * root.width / 2000)
                    frames[index].y = parseInt(y * root.height / 1000) - parseInt(h * root.height / 2000)
                    // AF情報ステータス1 AF合焦OK：AF合焦枠表示なし 以外 0x0000FFFF 非合焦 以外 4 ローライトAF中 以外 かつ
                    // 簡易1点の場合、白枠表示
                    if((s != LT.Utilities.AfInfoStatus_OK_NoDisp)
                        && (s != LT.Utilities.AfInfoStatus_Unfocused)
                        && (s != LT.Utilities.AfInfoStatus_InProgress)
                        && (s != LT.Utilities.AfInfoStatus_LowRight)
                        && (v == 1)) {
                        frames[index].changeMode(frames[index].afmode_sq_normal_white)
                        frames[index].visible = true
                        LTSubFunction.console_debug.out("changeFrame main face white")
                    }
                    // AF情報ステータス1 AF合焦OK：AF合焦枠表示なし 以外 0x0000FFFF 非合焦 以外 4 ローライトAF中 以外 かつ
                    // 合焦枠情報1 AF枠表示：緑枠
                    else if((s != LT.Utilities.AfInfoStatus_OK_NoDisp)
                            && (s != LT.Utilities.AfInfoStatus_Unfocused)
                            && (s != LT.Utilities.AfInfoStatus_InProgress)
                            && (s != LT.Utilities.AfInfoStatus_LowRight)
                            && (f == LT.Utilities.AfInfoDispFrame_Green) ) {
                        frames[index].changeMode(frames[index].afmode_sq_normal_green)
                        frames[index].visible = true
                        LTSubFunction.console_debug.out("changeFrame main face green")
                    }
                    // AF情報ステータス1 AF合焦OK：AF合焦枠表示なし 以外 0x0000FFFF 非合焦 以外 4 ローライトAF中 以外 かつ
                    // 合焦枠情報2 AF枠表示：赤枠
                    else if((s != LT.Utilities.AfInfoStatus_OK_NoDisp)
                            && (s != LT.Utilities.AfInfoStatus_Unfocused)
                            && (s != LT.Utilities.AfInfoStatus_InProgress)
                            && (s != LT.Utilities.AfInfoStatus_LowRight)
                            && (f == LT.Utilities.AfInfoDispFrame_Red) ) {
                        frames[index].changeMode(frames[index].afmode_sq_normal_red)
                        frames[index].visible = true
                        LTSubFunction.console_debug.out("changeFrame main face red")
                    }
                    // AF情報ステータス1 AF合焦OK：AF合焦枠表示なし 以外 0x0000FFFF 非合焦 以外 4 ローライトAF中 以外 かつ
                    // 合焦枠情報0 AF枠表示：なし
                    else if((s != LT.Utilities.AfInfoStatus_OK_NoDisp)
                            && (s != LT.Utilities.AfInfoStatus_Unfocused)
                            && (s != LT.Utilities.AfInfoStatus_InProgress)
                            && (s != LT.Utilities.AfInfoStatus_LowRight)
                            && (f == LT.Utilities.AfInfoDispFrame_Not) ) {
                        frames[index].visible = false
                        LTSubFunction.console_debug.out("changeFrame main face no")
                    }
                    // AF情報ステータス1 AF合焦OK：AF合焦枠表示なし 以外 0x0000FFFF 非合焦 以外 4 ローライトAF中 以外 かつ
                    // 上記以外
                    else if((s != LT.Utilities.AfInfoStatus_OK_NoDisp)
                            && (s != LT.Utilities.AfInfoStatus_Unfocused)
                            && (s != LT.Utilities.AfInfoStatus_InProgress)
                            && (s != LT.Utilities.AfInfoStatus_LowRight)) {
                        frames[index].changeMode(frames[index].afmode_sq_normal_yellow)
                        frames[index].visible = true
                        LTSubFunction.console_debug.out("changeFrame main face yellow1")
                    }
                    // AF情報ステータス0x0000FFFF 非合焦 または
                    // AF情報ステータス4 ローライトAF中
                    else if((s == LT.Utilities.AfInfoStatus_InProgress)
                            || (s == LT.Utilities.AfInfoStatus_Unfocused)
                            || (s == LT.Utilities.AfInfoStatus_LowRight) ) {
                        if(mode == afmode_face_af) {
                            frames[index].changeMode(frames[index].afmode_sq_normal_white)
                        } else {
                            frames[index].changeMode(frames[index].afmode_sq_normal_yellow)
                        }
                        frames[index].visible = true
                        LTSubFunction.console_debug.out("changeFrame main face yellow2")
                    }
                    // 上記以外に当てはまらない 白色で表示
                    else {
                        frames[index].changeMode(frames[index].afmode_sq_normal_white)
                        frames[index].visible = true
                        LTSubFunction.console_debug.out("changeFrame main face white")
                    }
                } else if(status == 1) {
                    //AF情報：顔検出ステータス：検出
                    LTSubFunction.console_debug.out("changeValue1 index=" + index + " status=" + status + " x=" + x + " y=" + y + " w=" + w + " h=" + h)
                    frames[index].width = parseInt(w * face_rect.parent_width / 1000)
                    frames[index].height = parseInt(h * face_rect.parent_height / 1000)
                    frames[index].x = parseInt(x * root.width / 1000) - parseInt(w * root.width / 2000)
                    frames[index].y = parseInt(y * root.height / 1000) - parseInt(h * root.height / 2000)
                    frames[index].changeMode(frames[index].afmode_sq_normal_white)
                    frames[index].visible = true
                } else {
                    //if(w*h) {
                    //    //AF情報：顔検出ステータス：検出
                    //    console.debug("changeValue3 index=" + index + " status=" + status + " x=" + x + " y=" + y + " w=" + w + " h=" + h)
                    //    frames[index].width = parseInt(w * face_rect.parent_width / 1000)
                    //    frames[index].height = parseInt(h * face_rect.parent_height / 1000)
                    //    frames[index].x = parseInt(x * root.width / 1000) - parseInt(w * root.width / 2000)
                    //    frames[index].y = parseInt(y * root.height / 1000) - parseInt(h * root.height / 2000)
                    //    frames[index].changeMode(frames[index].afmode_sq_normal_white)
                    //    frames[index].visible = true
                    //} else {
                        //AF情報：顔検出ステータス：未検出
                        face_detect_w[index] = 0
                        face_detect_h[index] = 0
                        frames[index].visible = false
                    //}
                }
                face_Frame = frames
            }
        }
        Component.onCompleted: {
            LTSubFunction.console_debug.out("LTAFFrame Component.onCompleted");
            var frames = face_Frame
            var detect_s = face_detect_s
            var detect_x = face_detect_x
            var detect_y = face_detect_y
            var detect_w = face_detect_w
            var detect_h = face_detect_h
            var component = Qt.createComponent("LTAFFrameSquare.qml");
            if (component.status === Component.Error) {
                console.log("Err createComponent LTAFFrameSquare: " + component.errorString())
            }
            //var width1 = parseInt((afframe225.width - f225_x_sep * (f225_x_num -1)) / f225_x_num)
            //var height1 = parseInt((afframe225.height - f225_y_sep * (f225_y_num -1)) / f225_y_num)
            for (var i=0; i<15; i++) {
                detect_s.push(0)
                detect_x.push(0)
                detect_y.push(0)
                detect_w.push(0)
                detect_h.push(0)
            }
            face_detect_s = detect_s
            face_detect_x = detect_x
            face_detect_y = detect_y
            face_detect_w = detect_w
            face_detect_h = detect_h
            //LTSubFunction.console_debug.out("LTAFFrame Component.onCompleted face_rect.face_detect_width[0] = " + face_detect_w[0]);
            //LTSubFunction.console_debug.out("LTAFFrame Component.onCompleted afframe.width = " + afframe.width);
            for (var i=0; i<15; i++) {
                var object = component.createObject(face_rect);
                object.index = i
                //object.width = Qt.binding(function() { return parseInt(face_rect.face_detect_width[this.index] * face_rect.parent_width / 1000) })
                //object.height = Qt.binding(function() { return parseInt(face_rect.face_detect_height[this.index] * face_rect.parent_height / 1000) })
                //object.x = Qt.binding(function() { return parseInt(face_rect.face_detect_x[this.index] * face_rect.parent_width / 1000) - parseInt(face_rect.face_detect_width[this.index] * face_rect.parent_width / 2000) })
                //object.y = Qt.binding(function() { return parseInt(face_rect.face_detect_y[this.index] * face_rect.parent_height / 1000) - parseInt(face_rect.face_detect_height[this.index] * face_rect.parent_height / 2000) })
                frames.push(object)
            }
            face_Frame = frames
            changeAllValue()
        }
    }

    //frame_chase
    LTAFFrameSquare {
        id: chase_detect_rect
        x: parseInt(root.chase_detect_x * afframe.width / 1000) - parseInt(root.chase_detect_width * afframe.width / 2000)
        y: parseInt(root.chase_detect_y * afframe.height / 1000) - parseInt(root.chase_detect_height * afframe.height / 2000)
        width: parseInt(root.chase_detect_width * afframe.width / 1000)
        height: parseInt(root.chase_detect_height * afframe.height / 1000)
        visible: false
    }

    // 225, 315 rect
    Item {
        id: afframe225
        property int f225_x_resolution: getFrame225ResolutionX()
        property int f225_y_resolution: getFrame225ResolutionY()
        property int f225_margin_left: getFrame225MarginH()
        property int f225_margin_right: getFrame225MarginH()
        property int f225_margin_top: getFrame225MarginV()
        property int f225_margin_bottom: getFrame225MarginV()
        property int f225_x_num: getFrame225SplitNumX()
        property int f225_y_num: getFrame225SplitNumY()
        property int f225_x_max: getAFDispSplitMaxNumX()
        property int f225_y_max: getAFDispSplitMaxNumY()
        property int f225_x_sep: 0
        property int f225_y_sep: 0
        x: afmode_point225f_calc_margin_x()
        y: afmode_point225f_calc_margin_y()
        width: root.width - 2*afmode_point225f_calc_margin_x()
        height: root.height - 2*afmode_point225f_calc_margin_y()
        visible: false
        property var point225_Frame: new Array
        Component.onCompleted: {
            LTSubFunction.console_debug.out("root width =" + root.width)
            LTSubFunction.console_debug.out("root height =" + root.height)
            LTSubFunction.console_debug.out("afframe225 width =" + afframe225.width)
            LTSubFunction.console_debug.out("afframe225 height =" + afframe225.height)
            var frames = point225_Frame
            var component = Qt.createComponent("LTAFFrame225.qml");
            if (component.status === Component.Error) {
                console.log("Err createComponent LTAFFrame225: " + component.errorString())
            }
            //var width1 = parseInt((afframe225.width - f225_x_sep * (f225_x_num -1)) / f225_x_num)
            //var height1 = parseInt((afframe225.height - f225_y_sep * (f225_y_num -1)) / f225_y_num)
            var f225_max = f225_x_max*f225_y_max
            for (var i=0; i<f225_max; i++) {
                var object = component.createObject(afframe225);
                object.index = i
                object.width = Qt.binding(function() { return (afframe225.width / f225_x_num) - f225_x_sep })
                object.height = Qt.binding(function() { return (afframe225.height / f225_y_num) - f225_y_sep })
                object.x = Qt.binding(function() { return (this.width + f225_x_sep) * (this.index % f225_x_num) })
                object.y = Qt.binding(function() { return (this.height + f225_y_sep) * parseInt(this.index / f225_x_num) })
                object.changeMode(object.mode_init)
                frames.push(object)
            }
            point225_Frame = frames
        }

        onWidthChanged: {
            if(afframe225.visible){
                // センター座標を再計算
                afmode_point225f_center_disp()
            }
        }
        onHeightChanged: {
            if(afframe225.visible){
                // センター座標を再計算
                afmode_point225f_center_disp()
            }
        }

        function afmode_point225f_calc_margin_x() {
            return parseInt((f225_margin_left * root.width) / f225_x_resolution)
        }
        function afmode_point225f_calc_margin_y() {
            return parseInt((f225_margin_top * root.height) / f225_y_resolution)
        }

        function disp_clear() {
            afmode_point225f_focus_disp_clear()
        }
        function afmode_point225f_focus_disp_clear() {
            var frames = afframe225.point225_Frame
            LTSubFunction.console_debug.out("afmode_point225f_focus_disp_clear")
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
            }
            afframe225.point225_Frame = frames
        }

        // 指定したエリアのAF枠のモードを変更する
        function changeModeSelectArea(s_org_x, s_org_y, e_org_x, e_org_y, mode) {
            var start_x = convToDispFrameX(s_org_x)
            var start_y = convToDispFrameY(s_org_y)
            var end_x = convToDispFrameX(e_org_x)
            var end_y = convToDispFrameY(e_org_y)
            var frames = afframe225.point225_Frame
            for(var i = start_x; i <= end_x; i ++) {
                for(var j = start_y; j <= end_y; j ++) {
                    var pos = j * f225_x_num + i
                    frames[pos].changeMode(mode)
                }
            }
            afframe225.point225_Frame = frames
        }

        // f225_x_max*f225_y_maxの枠座標からf225_x_num*f225_y_numの枠座標に変換
        function convToDispFrameX(in_x) {
            return in_x - (f225_x_max - f225_x_num)/2
        }
        function convToDispFrameY(in_y) {
            return in_y - (f225_y_max - f225_y_num)/2
        }

        function afmode_point225f_mouse_click(mouse_x, mouse_y) {
            //if(afaeStartFlg) {
            //    return
            //}
            var frames = afframe225.point225_Frame
            var width1 = afframe225.width / f225_x_num
            var height1 = afframe225.height / f225_y_num
            var width2 = width1 - f225_x_sep
            var height2 = height1 - f225_y_sep
            //f225_pos_x = Math.min(parseInt(mouse_x/width1), f225_x_num-1)
            //f225_pos_y = Math.min(parseInt(mouse_y/height1), f225_y_num-1)
            var v_f225_pos_x = Math.min(parseInt(mouse_x/width2), f225_x_num-1)
            var v_f225_pos_y = Math.min(parseInt(mouse_y/height2), f225_y_num-1)
            var x_before = (width2 * v_f225_pos_x) + afmode_point225f_calc_margin_x() + (width2/2)
            var y_before = (height2 * v_f225_pos_y) + afmode_point225f_calc_margin_y() + (height2/2)
            //root.center_x = (width1 * f225_pos_x) + parseInt(width2/2) + root.f225_margin_left
            //root.center_y = (height1 * f225_pos_y) + parseInt(height2/2) + root.f225_margin_top
            //root.center_x = parseInt( (x_before * 1000) / afframe.width )
            //root.center_y = parseInt( (y_before * 1000) / afframe.height )
            var v_center_x = parseInt( (x_before * 1000) / afframe.width )
            var v_center_y = parseInt( (y_before * 1000) / afframe.height )
            var start_x = Math.max(0, v_f225_pos_x - parseInt(f225_length/2));
            var end_x = Math.min(f225_x_num-1, v_f225_pos_x + parseInt(f225_length/2));
            var start_y = Math.max(0, v_f225_pos_y - parseInt(f225_length/2));
            var end_y = Math.min(f225_y_num-1, v_f225_pos_y + parseInt(f225_length/2));
            var i = 0
            var j = 0
            var ret1 = LT.DeviceAdapter.Ternary_False
            var ret2 = LT.DeviceAdapter.Ternary_True
            var ret3 = LT.DeviceAdapter.Ternary_True
            var same_pos = true
            if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                same_pos = false
            }
            if(mode == afmode_point225) {
                // 225点APIを呼ぶ
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225 x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
                if((!same_pos)&&(ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                    // モードをafmode_point225_afに変える
                    changeMode(afmode_point225_af)
                }
            } else if(mode == afmode_point225s) {
                // 225点APIを呼ぶ
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225 x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            } else if(mode == afmode_point225f) {
                // 225点APIを呼ぶ
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225f x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
                if((!same_pos)&&(ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                    // モードをafmode_point225f_afに変える
                    changeMode(afmode_point225f_af)
                }
            } else if(mode == afmode_point225sf) {
                // 225点APIを呼ぶ
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225f x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            } else if(mode == afmode_point225_af) {
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225_af x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            } else if(mode == afmode_point225s_af) {
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225_af x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            } else if(mode == afmode_point225f_af) {
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225f_af x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            } else if(mode == afmode_point225sf_af) {
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225f_af x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            }
            if(mode == afmode_face_225) {
                // 225点APIを呼ぶ
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225 x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
                if((!same_pos)&&(ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                    // モードをafmode_face_225_afに変える
                    changeMode(afmode_face_225_af)
                }
            } else if(mode == afmode_face_225f) {
                // 225点APIを呼ぶ
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225f x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
                if((!same_pos)&&(ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                    // モードをafmode_face_225f_afに変える
                    changeMode(afmode_face_225f_af)
                }
            } else if(mode == afmode_face_225_af) {
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225_af x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            } else if(mode == afmode_face_225f_af) {
                //deviceAdapter.adp_LMX_func_api_RecInfo_AF_Frame_Set_Multi_AF_Frame(f225_pos_x + f225_pos_y * f225_x_num);
                //LTSubFunction.console_debug.out("afmode_point225f_mouse_click afmode_point225f_af x=" + f225_pos_x + " y=" + f225_pos_y)
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(f225_pos_x, f225_pos_y);
                //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(f225_pos_x, f225_pos_y);
                if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                    deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                    deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                    ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                    ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                    ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                }
            }
            if((!same_pos)&&(ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                for(i = 0; i < frames.length ; i ++) {
                    frames[i].changeMode(frames[i].mode_init)
                    frames[i].visible = true
                    if(afmode[mode].frame_225){
                    //    frames[i].visible = false
                        frames[i].changeMode(frames[i].mode_init)
                    } else if(afmode[mode].frame_225f){
                    //    frames[i].visible = true
                    } else if(afmode[mode].frame_225s){
                    //    frames[i].visible = false
                        frames[i].changeMode(frames[i].mode_init)
                    } else if(afmode[mode].frame_custom){
                    //    frames[i].visible = false
                        frames[i].changeMode(frames[i].mode_init)
                    } else if(afmode[mode].frame_customf){
                    //    frames[i].visible = false
                        frames[i].changeMode(frames[i].mode_init)
                    }
                }
                //for(i = start_x; i <= end_x; i ++) {
                //    for(j = start_y; j <= end_y; j ++) {
                //        frames[ j * f225_x_num + i ].changeMode(frames[ j * f225_x_num + i ].mode_yellow)
                //        //frames[ j * f225_x_num + i ].visible = true
                //    }
                //}
                f225_timer.restart()
            }
            //f225_timer.running = true
            afframe225.point225_Frame = frames
        }

        function afmode_point225f_center_disp() {
            LTSubFunction.console_debug.out("afmode_point225f_disp mode=" + mode + " f225_x_num=" + f225_x_num + " f225_y_num=" + f225_y_num + " f225_x_sep=" + f225_x_sep + " f225_y_sep=" + f225_y_sep)
            LTSubFunction.console_debug.out("afmode_point225f_disp afframe225.width=" + afframe225.width + " afframe225.height=" + afframe225.height + " f225_pos_x=" + f225_pos_x + " f225_pos_y=" + f225_pos_y)
            var width1 = afframe225.width / f225_x_num
            var height1 = afframe225.height / f225_y_num
            var width2 = width1 - f225_x_sep
            var height2 = height1 - f225_y_sep
            var pos_x = convToDispFrameX(f225_pos_x)
            var pos_y = convToDispFrameY(f225_pos_y)
            var x_before = (width1 * pos_x) + (width2/2) + afmode_point225f_calc_margin_x()
            var y_before = (height1 * pos_y) + (height2/2) + afmode_point225f_calc_margin_y()
            var center_x = parseInt( (x_before * 1000) / afframe.width )
            var center_y = parseInt( (y_before * 1000) / afframe.height )
            root.center_x = center_x
            root.center_y = center_y
            LTSubFunction.console_debug.out("afmode_point225f_disp x=" + center_x + " y=" + center_y)
            //ゾーンの場合は中心点の計算が違うようなので、さらに呼び出して更新する
            if( center_plus.visible === true && zone_outer.visible === true ){
                zone_outer.zone_center_disp()
            }
        }

        function afmode_point225f_disp() {
            LTSubFunction.console_debug.out("afmode_point225f_disp mode=" + mode)
            var frames = afframe225.point225_Frame
            var same_pos = false
            var center_x = root.center_x
            var center_y = root.center_y
            afmode_point225f_center_disp()
            if( (center_x == root.center_x) && (center_y == root.center_y) && (root.f225_length == root.f225_length_old) ) {
                same_pos = true
            }
            var pos_x = convToDispFrameX(f225_pos_x)
            var pos_y = convToDispFrameY(f225_pos_y)
            var start_x = Math.max(0, pos_x - parseInt(f225_length/2));
            var end_x = Math.min(f225_x_num-1, pos_x + parseInt(f225_length/2));
            var start_y = Math.max(0, pos_y - parseInt(f225_length/2));
            var end_y = Math.min(f225_y_num-1, pos_y + parseInt(f225_length/2));
            var i = 0
            var j = 0
            //LTSubFunction.console_debug.out("afmode_point225f_disp same_pos=" + same_pos)
            //LTSubFunction.console_debug.out("afmode_point225f_disp start_x=" + start_x)
            //LTSubFunction.console_debug.out("afmode_point225f_disp end_x=" + end_x)
            //LTSubFunction.console_debug.out("afmode_point225f_disp start_y=" + start_y)
            //LTSubFunction.console_debug.out("afmode_point225f_disp end_y=" + end_y)
            for(i = 0; i < frames.length ; i ++) {
                //frames[i].visible = true
                if ( ( (mode == afmode_point225f) || (mode == afmode_point225sf) || (mode == afmode_point225f_af) || (mode == afmode_point225sf_af) ) &&
                     ( (start_x <= i % f225_x_num) && (i % f225_x_num <= end_x) ) &&
                     ( (start_y <= parseInt(i / f225_y_num)) && (parseInt(i / f225_y_num) <= end_y) ) ) {
                    //if(!same_pos) {
                    //    frames[i].changeMode(frames[i].mode_lightgray)
                    //}
                    if( f225_timer.running == true ) {
                        frames[i].changeMode(frames[i].mode_yellow)
                    }
                    else {
                        frames[i].changeMode(frames[i].mode_lightgray)
                    }

                    //frames[i].visible = true
                }
                else if (
                    ( (mode == afmode_point225) || (mode == afmode_point225s) || (mode == afmode_point225_af) || (mode == afmode_point225s_af) ) &&
                    ( f225_timer.running == true ) &&
                    ( (start_x <= i % f225_x_num) && (i % f225_x_num <= end_x) ) &&
                    ( (start_y <= parseInt(i / f225_y_num)) && (parseInt(i / f225_y_num) <= end_y) ) ) {
                    //if(same_pos) {
                        frames[i].changeMode(frames[i].mode_yellow)
                    //}
                    //frames[i].visible = true
                }
                else if (
                    ( (mode == afmode_point225) || (mode == afmode_point225s) || (mode == afmode_point225_af) || (mode == afmode_point225s_af) ) &&
                    ( (start_x <= i % f225_x_num) && (i % f225_x_num <= end_x) ) &&
                    ( (start_y <= parseInt(i / f225_y_num)) && (parseInt(i / f225_y_num) <= end_y) ) ) {
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
                else if (
                    ( (mode == afmode_face_225) || (mode == afmode_face_225_af) ) &&
                    ( f225_timer.running == true ) &&
                    ( (start_x <= i % f225_x_num) && (i % f225_x_num <= end_x) ) &&
                    ( (start_y <= parseInt(i / f225_y_num)) && (parseInt(i / f225_y_num) <= end_y) ) ) {
                    //if(same_pos) {
                        frames[i].changeMode(frames[i].mode_yellow)
                    //}
                    //frames[i].visible = true
                }
                else if (
                    ( (mode == afmode_face_225) || (mode == afmode_face_225_af) ) &&
                    ( (start_x <= i % f225_x_num) && (i % f225_x_num <= end_x) ) &&
                    ( (start_y <= parseInt(i / f225_y_num)) && (parseInt(i / f225_y_num) <= end_y) ) ) {
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
                else if(afmode[mode].frame_225){
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
                else if(afmode[mode].frame_225f){
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
                else if(afmode[mode].frame_225s){
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
                else if(afmode[mode].frame_custom){
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
                else if(afmode[mode].frame_customf){
                    frames[i].changeMode(frames[i].mode_init)
                    //frames[i].visible = false
                }
            }
            //if(!same_pos) {
            //    f225_timer.running = false
            //}
            afframe225.point225_Frame = frames
        }

        function afmode_point225f_focus_disp() {
            var frames = afframe225.point225_Frame
            LTSubFunction.console_debug.out("afmode_point225f_focus_disp length =" + root.focus_frame.length)
            var i = 0
            var frame_num = f225_x_num*f225_y_num
            for(i = 0; i < frames.length ; i ++) {
                if(i < frame_num) {
                    if(frames[i].mode == frames[i].mode_green_b) {
                        if(f225_timer.running) {
                            frames[i].changeMode(frames[i].mode_yellow)
                        } else if( afframe.mode == afframe.afmode_point225f ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_point225sf ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_point225f_af ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_point225sf_af ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_customf ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_customsf ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_customf_af ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else if( afframe.mode == afframe.afmode_customsf_af ) {
                            frames[i].changeMode(frames[i].mode_lightgray)
                        } else {
                            frames[i].changeMode(frames[i].mode_init)
                        }
                    }
                } else {
                    frames[i].changeMode(frames[i].mode_init)
                }
            }
            for(i = 0; i < root.focus_frame.length ; i ++) {
                //LTSubFunction.console_debug.out("afmode_point225f_focus_disp root.focus_frame[i][1] =" + root.focus_frame[i][1])
                //LTSubFunction.console_debug.out("afmode_point225f_focus_disp root.focus_frame[i][0] =" + root.focus_frame[i][0])
                var x = convToDispFrameX(root.focus_frame[i][0])
                var y = convToDispFrameY(root.focus_frame[i][1])
                if( ((0 <= x) && (x < f225_x_num)) && ((0 <= y) && (y < f225_y_num)) ) {
                    var pos = y * f225_x_num + x
                    LTSubFunction.console_debug.out("afmode_point225f_focus_disp pos =" + pos)
                    frames[pos].changeMode(frames[pos].mode_green_b)
                    //frames[pos].visible = true
                }
            }
            afframe225.point225_Frame = frames
        }

        function afmode_customf_mouse_click(mouse_x, mouse_y) {
            //LTSubFunction.console_debug.out("afmode_customf_mouse_click autoFocusMode=" + deviceAdapter.autoFocusMode)
            switch(deviceAdapter.autoFocusMode) {
            case LT.Utilities.AFM_CustomVertical:// ,
            case LT.Utilities.AFM_CustomHorizon://  ,
            case LT.Utilities.AFM_CustomCenter://   ,
            // ivc >> start >> No.3 -> nakhuong
            case LT.Utilities.AFM_VertHori://       ,
            case LT.Utilities.AFM_Square://         ,
            case LT.Utilities.AFM_Ellipse://        ,
            // ivc << end << No.3 -> nakhuong
                afmode_customf_mouse_click_change(mouse_x, mouse_y)
                break;
            case LT.Utilities.AFM_CustomC1://       ,
            case LT.Utilities.AFM_CustomC2://       ,
            case LT.Utilities.AFM_CustomC3://       ,
            // ivc >> start >> No.3 -> nakhuong
            case LT.Utilities.AFM_Custom1://        ,
            case LT.Utilities.AFM_Custom2://        ,
            case LT.Utilities.AFM_Custom3://        ,
            // ivc << end << No.3 -> nakhuong
                if (afmode_customf_mouse_click_change(mouse_x, mouse_y) === LT.DeviceAdapter.Ternary_False) {    // 2018/11/09 Panasoni Nakano
                    afmode_customf_mouse_click_disp();
                }
                break;
            default:
                break;
            }
        }
        function afmode_customf_mouse_click_disp() {
            var frames = afframe225.point225_Frame
            var i = 0
            for(i = 0; i < frames.length; i ++) {
                //frames[i].changeMode(frames[i].mode_lightgray)
                frames[i].changeMode(frames[i].mode_init)
                //frames[i].visible = false
            }
            //LTSubFunction.console_debug.out("afmode_customf_mouse_click_disp length =" + root.custom_frame.length)
            for(i = 0; i < root.custom_frame.length ; i ++) {
                //LTSubFunction.console_debug.out("afmode_customf_mouse_click_disp root.custom_frame[i][1] =" + root.custom_frame[i][1])
                //LTSubFunction.console_debug.out("afmode_customf_mouse_click_disp root.custom_frame[i][0] =" + root.custom_frame[i][0])
                var x = convToDispFrameX(root.custom_frame[i][0])
                var y = convToDispFrameY(root.custom_frame[i][1])
                if( ((0 <= x) && (x < f225_x_num)) && ((0 <= y) && (y < f225_y_num)) ) {
                    var pos = y * f225_x_num + x
                    //LTSubFunction.console_debug.out("afmode_customf_mouse_click_disp pos =" + pos)
                    frames[pos].changeMode(frames[pos].mode_yellow)
                    //frames[pos].visible = true
                }
            }
            afframe225.point225_Frame = frames
            f225_timer.restart()
            //f225_timer.running = true
        }
        function afmode_customf_mouse_click_change(mouse_x, mouse_y) {
            var frames = afframe225.point225_Frame
            var width1 = afframe225.width / f225_x_num
            var height1 = afframe225.height / f225_y_num
            var width2 = width1 - f225_x_sep
            var height2 = height1 - f225_y_sep
            //f225_pos_x = Math.min(parseInt(mouse_x/width1), f225_x_num-1)
            //f225_pos_y = Math.min(parseInt(mouse_y/height1), f225_y_num-1)
            var v_f225_pos_x = Math.min(parseInt(mouse_x/width2), f225_x_num-1)
            var v_f225_pos_y = Math.min(parseInt(mouse_y/height2), f225_y_num-1)
            var x_before = (width2 * v_f225_pos_x) + afmode_point225f_calc_margin_x() + (width2/2)
            var y_before = (height2 * v_f225_pos_y) + afmode_point225f_calc_margin_y() + (height2/2)
            //root.center_x = (width1 * f225_pos_x) + parseInt(width2/2) + root.f225_margin_left
            //root.center_y = (height1 * f225_pos_y) + parseInt(height2/2) + root.f225_margin_top
            //root.center_x = parseInt( (x_before * 1000) / afframe.width )
            //root.center_y = parseInt( (y_before * 1000) / afframe.height )
            var v_center_x = parseInt( (x_before * 1000) / afframe.width )
            var v_center_y = parseInt( (y_before * 1000) / afframe.height )
            var start_x = Math.max(0, v_f225_pos_x - parseInt(f225_length/2));
            var end_x = Math.min(f225_x_num-1, v_f225_pos_x + parseInt(f225_length/2));
            var start_y = Math.max(0, v_f225_pos_y - parseInt(f225_length/2));
            var end_y = Math.min(f225_y_num-1, v_f225_pos_y + parseInt(f225_length/2));
            var i = 0
            var j = 0
            var ret1 = LT.DeviceAdapter.Ternary_False
            var ret2 = LT.DeviceAdapter.Ternary_True
            var ret3 = LT.DeviceAdapter.Ternary_True
            if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
            }
            //afframe225.point225_Frame = frames
            if((ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                //for(i = 0; i < frames.length ; i ++) {
                //    frames[i].changeMode(frames[i].mode_init)
                //    frames[i].visible = true
                //}
                f225_timer.restart()
            } else { // 2018/11/09 Panasoni Nakano
                return LT.DeviceAdapter.Ternary_False;
            }

            //f225_timer.running = true
        }

        function afmode_customf_disp() {
            //LTSubFunction.console_debug.out("afmode_customf_disp")
            var frames = afframe225.point225_Frame
            var i = 0
            for(i = 0; i < frames.length; i ++) {
                //frames[i].changeMode(frames[i].mode_lightgray)
                frames[i].changeMode(frames[i].mode_init)
                //frames[i].visible = false
            }
            //LTSubFunction.console_debug.out("afmode_customf_disp length =" + root.custom_frame.length)
            for(i = 0; i < root.custom_frame.length ; i ++) {
                //LTSubFunction.console_debug.out("afmode_customf_disp root.custom_frame[i][1] =" + root.custom_frame[i][1])
                //LTSubFunction.console_debug.out("afmode_customf_disp root.custom_frame[i][0] =" + root.custom_frame[i][0])
                var x = convToDispFrameX(root.custom_frame[i][0])
                var y = convToDispFrameX(root.custom_frame[i][1])
                if( ((0 <= x) && (x < f225_x_num)) && ((0 <= y) && (y < f225_y_num)) ) {
                    var pos = y * f225_x_num + x
                    //LTSubFunction.console_debug.out("afmode_customf_disp pos =" + pos)
                    if(f225_timer.running) {
                        frames[pos].changeMode(frames[pos].mode_yellow)
                        //frames[pos].visible = true
                    } else if( (afframe.mode == afframe.afmode_customf) || (afframe.mode == afframe.afmode_customsf) || (afframe.mode == afframe.afmode_customf_af) || (afframe.mode == afframe.afmode_customsf_af) ) {
                        frames[pos].changeMode(frames[pos].mode_lightgray)
                        //frames[pos].visible = true
                    }
                }
            }
            afframe225.point225_Frame = frames
        }
        function f225_focus_timer_Triggered() {
            LTSubFunction.console_debug.out("f225_focus_timer_Triggered")
            f225_focus_timer.running = false
            var frames = afframe225.point225_Frame
            for(var i = 0; i < frames.length; i ++) {
                if(i < f225_x_num*f225_y_num) {
                    //if( (frames[i].mode == frames[i].mode_yellow) || (frames[i].mode == frames[i].mode_green_b) ) {
                    if(frames[i].mode == frames[i].mode_green_b) {
                        if ( (mode == afmode_point225_af) || (mode == afmode_face_225_af) ) {
                            frames[i].changeMode(frames[i].mode_init)
                        } else if ( (mode == afmode_point225f_af) || (mode == afmode_face_225f_af) ) {
                            if(f225_timer.running) {
                                frames[i].changeMode(frames[i].mode_yellow)
                            } else {
                                frames[i].changeMode(frames[i].mode_lightgray)
                            }
                        }
                    }
                } else {
                    frames[i].changeMode(frames[i].mode_init)
                }
            }
            afframe225.point225_Frame = frames
        }

        MouseArea {
            anchors.fill: parent
            onClicked:(mouse)=> {
                LTSubFunction.console_debug.out("afframe225 onClicked mode="+mode)
                //if(!afaeStartFlg) {
                    if((mode == afmode_point225) || (mode == afmode_point225s) || (mode == afmode_point225_af) || (mode == afmode_point225s_af) || (mode == afmode_point225f) || (mode == afmode_point225sf) || (mode == afmode_point225f_af) || (mode == afmode_point225sf_af) /*||
                       (mode == afmode_face_225) || (mode == afmode_face_225_af) || (mode == afmode_face_225f) || (mode == afmode_face_225f_af)*/ ) {
                        //LTSubFunction.console_debug.out("afframe225 225")
                        afframe225.afmode_point225f_mouse_click(mouse.x, mouse.y)
                    } else if( (mode == afmode_custom) || (mode == afmode_customs) || (mode == afmode_customsf) || (mode == afmode_customf) || (mode == afmode_custom_af) || (mode == afmode_customf_af) || (mode == afmode_customs_af) || (mode == afmode_customsf_af) ) {
                        //LTSubFunction.console_debug.out("afframe225 custom")
                        afframe225.afmode_customf_mouse_click(mouse.x, mouse.y)
                    } else if( (mode == afmode_face) || (mode == afmode_face_eye) || (mode == afmode_face_af) ) {
                        var x_conv = parseInt( ((mouse.x+afframe225.afmode_point225f_calc_margin_x()) * 1000) / afframe.width )
                        var y_conv = parseInt( ((mouse.y+afframe225.afmode_point225f_calc_margin_y()) * 1000) / afframe.height )
                        if(deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) {
                            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_START(x_conv, y_conv);
                        } else {
                            // 顔設定APIを呼ぶ
                            //deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_1POINT_AF(x_conv, y_conv);
                            var ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                            var ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                            var ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                            if((ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
                                // モードをafmode_face_afに変える
                                changeMode(afmode_face_af)
                            }
                        }
                    } else if((mode == afmode_fullarea) || (mode == afmode_fullarea_af) || (mode == afmode_fullareaf) || (mode == afmode_fullareaf_af)) {
                        var x_conv = parseInt( ((mouse.x+afframe225.afmode_point225f_calc_margin_x()) * 1000) / afframe.width )
                        var y_conv = parseInt( ((mouse.y+afframe225.afmode_point225f_calc_margin_y()) * 1000) / afframe.height )
                        if(deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) {
                            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_START(x_conv, y_conv);
                        } else {
                            var ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                            var ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                            var ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                        }
                        
                    }
                //}
            }
        }
        Timer {
            id: f225_focus_timer
            interval: 500; running: false; repeat: false
            onTriggered: {
                LTSubFunction.console_debug.out("f225_focus_timer onTriggered")
                afframe225.f225_focus_timer_Triggered()
            }
        }

        Timer {
            id: f225_timer
            interval: 5000; running: false; repeat: false
            onTriggered: {
                LTSubFunction.console_debug.out("f225_timer onTrigger")
                var frames = afframe225.point225_Frame
                var frame_max = afframe225.f225_x_num*afframe225.f225_y_num
                for(var i = 0; i < frames.length; i ++) {
                    if(i < frame_max) {
                        if(afmode[mode].frame_225){
                            //frames[i].visible = false
                            //if( (frames[i].mode == frames[i].mode_yellow) || (frames[i].mode == frames[i].mode_green_b) ) {
                            if(frames[i].mode == frames[i].mode_yellow) {
                                frames[i].changeMode(frames[i].mode_init)
                            }
                        } else if(afmode[mode].frame_225f){
                            if(frames[i].mode == frames[i].mode_yellow) {
                                frames[i].changeMode(frames[i].mode_lightgray)
                            }
                        } else if(afmode[mode].frame_225s){
                            if(frames[i].mode == frames[i].mode_yellow) {
                                //frames[i].visible = true
                                frames[i].changeMode(frames[i].mode_lightgray)
                            } else if(frames[i].mode != frames[i].mode_green_b) {
                                frames[i].changeMode(frames[i].mode_init)
                                //frames[i].visible = false
                            }
                        } else if(afmode[mode].frame_custom){
                            frames[i].changeMode(frames[i].mode_init)
                            //frames[i].visible = false
                        } else if(afmode[mode].frame_customf){
                            if(frames[i].mode == frames[i].mode_yellow) {
                                //frames[i].visible = true
                                frames[i].changeMode(frames[i].mode_lightgray)
                            } else if(frames[i].mode == frames[i].mode_lightgray) {
                                frames[i].changeMode(frames[i].mode_lightgray)
                            } else {
                                frames[i].changeMode(frames[i].mode_init)
                                //frames[i].visible = false
                            }
                        }
                    } else {
                        frames[i].changeMode(frames[i].mode_init)
                    }
                }
                afframe225.point225_Frame = frames
            }
        }
    }

    // PDAF枠
    Item {
        id: afframePDAF
        anchors.fill: parent
        visible: false
        property int centerX: frame779SplitMaxNumX/2  // 中心の枠
        property int centerY: frame779SplitMaxNumY/2  // 中心の枠
        property var pdaf_Frame: new Array
        property var pdaf_hori_Frame: new Array
        property var pdaf_vert_Frame: new Array
        Component.onCompleted: {
            var frames = pdaf_Frame
            var component = Qt.createComponent("LTAFFrame225.qml");
            var frame_max = frame779SplitMaxNumX*frame779SplitMaxNumY
            // フルエリア、ゾーンPDAF枠作成
            var i = 0
            for (i=0; i<frame_max; i++) {
                var object = component.createObject(afframePDAF);
                object.index = i
                object.width = Qt.binding(calcFrameSizeH)
                object.height = Qt.binding(calcFrameSizeV)
                // 座標は中心の枠を基準に計算(->中心の枠は画像の中心から移動しない)
                object.x = Qt.binding(function() { return ((root.width/2)-(calcFrameSizeH()/2)) - calcRangeFromCenterX(this.index) })
                object.y = Qt.binding(function() { return ((root.height/2)-(calcFrameSizeV()/2)) - calcRangeFromCenterY(this.index) })
                object.changeMode(object.mode_init)
                frames.push(object)
            }
            pdaf_Frame = frames
            // ゾーン横PDAF枠作成
            frames = pdaf_hori_Frame
            for (i=0; i<frame779SplitMaxNumX; i++) {
                var object = component.createObject(afframePDAF);
                object.index = i
                object.width = Qt.binding(calcFrameSizeH)
                object.height = Qt.binding(calcFrameSizeV)
                // 座標は中心の枠を基準に計算(->中心の枠は画像の中心から移動しない)
                object.x = Qt.binding(function() { return ((root.width/2)-(calcFrameSizeH()/2)) - calcRangeFromCenterX(this.index) })
                object.y = Qt.binding(calc_pdaf_hori_y)
                object.changeMode(object.mode_init)
                frames.push(object)
            }
            pdaf_hori_Frame = frames
            //ゾーン縦PDAF枠作成
            frames = pdaf_vert_Frame
            for (i=0; i<frame779SplitMaxNumY; i++) {
                var object = component.createObject(afframePDAF);
                object.index = i*frame779SplitMaxNumX
                object.width = Qt.binding(calcFrameSizeH)
                object.height = Qt.binding(calcFrameSizeV)
                // 座標は中心の枠を基準に計算(->中心の枠は画像の中心から移動しない)
                object.x = Qt.binding(calc_pdaf_vert_x)
                object.y = Qt.binding(function() { return ((root.height/2)-(calcFrameSizeV()/2)) - calcRangeFromCenterY(this.index) })
                object.changeMode(object.mode_init)
                frames.push(object)
            }
            pdaf_vert_Frame = frames
        }

        // PDAF の表示が正しく行われないので遅れて再設定を行う　2024/10 tsutsumi
        Timer {
            id: afframePDAF_timer
            interval: 300; running: false; repeat: false
            property bool sizeChangeMode: false
            onTriggered: {
//                console.debug("タイマー終了")
                if( sizeChangeMode === false ){
                    afframePDAF.pdaf_frame_focus_disp_update()
                }else{
                    afframePDAF.disp_update()
                }
            }
        }

        // 中心点距離(X)の表示スケールを計算
        function calcFrameIntervalX() {
            return parseInt((getFrame779FrameIntervalX() * root.width) / getFrame779ResolutionX())
        }
        // 中心点距離(Y)の表示スケールを計算
        function calcFrameIntervalY() {
            return parseInt((getFrame779FrameIntervalY() * root.height) / getFrame779ResolutionY())
        }
        // 緑枠サイズ(幅)の表示スケールを計算
        function calcFrameSizeH() {
            return parseInt((getFrame779FrameSizeH() * root.width) / getFrame779ResolutionX())
        }
        // 緑枠サイズ(高さ)の表示スケールを計算
        function calcFrameSizeV() {
            return parseInt((getFrame779FrameSizeV() * root.height) / getFrame779ResolutionY())
        }
        // 中心点までの距離を計算(X座標)
        function calcRangeFromCenterX(index) {
            var x = index % frame779SplitMaxNumX
            return (centerX-x)*calcFrameIntervalX()
        }
        // 中心点までの距離を計算(Y座標)
        function calcRangeFromCenterY(index) {
            var y = parseInt(index / frame779SplitMaxNumX)
            return (centerY-y)*calcFrameIntervalY()
        }
        // ゾーン縦のPDAF枠のX座標計算
        function calc_pdaf_vert_x(){
            // root座標系のzone_outerの中心X座標を計算
            var idx = (zone_outer.minX + parseInt(((zone_outer.maxX+1) - zone_outer.minX)/2))
            var zone_x = zone_outer.calc_margin_x() + idx*zone_outer.frame_width + zone_outer.frame_width/2
            // root座標系からafframePDAF座標系に変換
            var frame_point = afframePDAF.mapFromItem(root, zone_x, 0)
            // X座標計算
            return frame_point.x - calcFrameSizeH()/2
        }
        // ゾーン横のPDAF枠のY座標計算
        function calc_pdaf_hori_y(){
            // root座標系のzone_outerの中心Y座標を計算
            var idx = (zone_outer.minY + parseInt(((zone_outer.maxY+1) - zone_outer.minY)/2))
            var zone_y = zone_outer.calc_margin_y() + idx*zone_outer.frame_height + zone_outer.frame_height/2
            // root座標系からafframePDAF座標系に変換
            var frame_point = afframePDAF.mapFromItem(root, 0, zone_y)
            // Y座標計算
            return frame_point.y - calcFrameSizeV()/2
        }
        
        // 表示クリア
        function disp_clear() {
            pdaf_frame_focus_disp_clear()
            pdaf_hori_frame_focus_disp_clear()
            pdaf_vert_frame_focus_disp_clear()
        }
        // PDAF枠クリア
        function pdaf_frame_focus_disp_clear() {
            var frames = pdaf_Frame
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
            }
            pdaf_Frame = frames
        }
        // ゾーン横PDAF枠クリア
        function pdaf_hori_frame_focus_disp_clear(){
            var frames = pdaf_hori_Frame
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
            }
            pdaf_hori_Frame = frames
        }
        // ゾーン縦PDAF枠クリア
        function pdaf_vert_frame_focus_disp_clear(){
            var frames = pdaf_vert_Frame
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
            }
            pdaf_vert_Frame = frames
        }

        function disp_update(){
            pdaf_frame_focus_disp_update()
            pdaf_hori_frame_focus_disp_update()
            pdaf_vert_frame_focus_disp_update()

        }
        function pdaf_frame_focus_disp_update() {
            var frames = pdaf_Frame
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].width = Qt.binding(calcFrameSizeH)
                frames[i].height = Qt.binding(calcFrameSizeV)
                // 座標は中心の枠を基準に計算(->中心の枠は画像の中心から移動しない)
                frames[i].x = Qt.binding(function() { return ((root.width/2)-(calcFrameSizeH()/2)) - calcRangeFromCenterX(i) })
                frames[i].y =  Qt.binding(function() { return ((root.height/2)-(calcFrameSizeV()/2)) - calcRangeFromCenterY(i) })
//                var y = root.height/2
//                var y1 = calcFrameSizeV()/2
//                var y2 = calcRangeFromCenterY(i)
//if ((i%200) == 50){
//console.debug(" pdaf_frame_focus_disp_update W H X Y:", i, " ", root.visible, " ", frames[i].x, " ", frames[i].y, " ",  y, " ", y1, " ", y2)
//}
            }
            pdaf_Frame = frames
        }
        function pdaf_hori_frame_focus_disp_update(){
            var frames = pdaf_hori_Frame
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].width = Qt.binding(calcFrameSizeH)
                frames[i].height = Qt.binding(calcFrameSizeV)
                // 座標は中心の枠を基準に計算(->中心の枠は画像の中心から移動しない)
                frames[i].x = Qt.binding(function() { return ((root.width/2)-(calcFrameSizeH()/2)) - calcRangeFromCenterX(this.index) })
                frames[i].y = Qt.binding(calc_pdaf_hori_y)
//console.info("pdaf_hori_Frame x:"+frames[i].x + " y:" + frames[i].y + " " + root.width + "," + root.height)
            }
            pdaf_hori_Frame = frames
        }
        function pdaf_vert_frame_focus_disp_update(){
            var frames = pdaf_vert_Frame
            var i = 0
            for(i = 0; i < frames.length ; i ++) {
                frames[i].width = Qt.binding(calcFrameSizeH)
                frames[i].height = Qt.binding(calcFrameSizeV)
                // 座標は中心の枠を基準に計算(->中心の枠は画像の中心から移動しない)
                frames[i].x = Qt.binding(calc_pdaf_vert_x)
                frames[i].y = Qt.binding(function() { return ((root.height/2)-(calcFrameSizeV()/2)) - calcRangeFromCenterY(this.index) })
            }
            pdaf_vert_Frame = frames
        }

        // カメラの枠座標から41x19の枠座標に変換
        function convToDispFrameX(in_x) {
            return in_x + (frame779SplitMaxNumX - getFrame779SplitNumX())/2
        }
        function convToDispFrameY(in_y) {
            return in_y + (frame779SplitMaxNumY - getFrame779SplitNumY())/2
        }

        function pdaf_frame_focus_disp() {
            if(deviceAdapter.autoFocusMode === LT.Utilities.AFM_VertHori &&
               zone_outer.outer_mode == zone_outer.afmode_outer_hori_pdaf){
                // ゾーン横PDAF枠
                pdaf_frame_focus_disp_clear()
                pdaf_vert_frame_focus_disp_clear()
                pdaf_hori_frame_focus_disp()
            }else if(deviceAdapter.autoFocusMode === LT.Utilities.AFM_VertHori &&
                     zone_outer.outer_mode == zone_outer.afmode_outer_vert_pdaf){
                // ゾーン縦PDAF枠
                pdaf_frame_focus_disp_clear()
                pdaf_hori_frame_focus_disp_clear()
                pdaf_vert_frame_focus_disp()
            }else{
                // フルエリア、ゾーンPDAF枠表示
                pdaf_hori_frame_focus_disp_clear()
                pdaf_vert_frame_focus_disp_clear()
                
                var frames = pdaf_Frame
                var i = 0
                // 初期化
                for(i = 0; i < frames.length ; i ++) {
                    frames[i].changeMode(frames[i].mode_init)
                }
                // フォーカス設定
                var mode = frames[0].mode_green
                for(i = 0; i < root.focus_pdaf.length ; i ++) {
                    var x = convToDispFrameX(root.focus_pdaf[i][0])
                    var y = convToDispFrameY(root.focus_pdaf[i][1])
                    var pos = y * frame779SplitMaxNumX + x
                    frames[pos].changeMode(mode)
                }
                pdaf_Frame = frames
            }
        }
        //  ゾーン横PDAF枠表示
        function pdaf_hori_frame_focus_disp(){
            var frames = pdaf_hori_Frame
            var i = 0
            // 初期化
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
            }
            // フォーカス設定
            var mode = frames[0].mode_green
            for(i = 0; i < root.focus_pdaf.length ; i ++) {
                var x = convToDispFrameX(root.focus_pdaf[i][0])
                var y = convToDispFrameY(root.focus_pdaf[i][1])
                frames[x].changeMode(mode)
            }
            pdaf_hori_Frame = frames
        }
        // ゾーン縦PDAF枠表示
        function pdaf_vert_frame_focus_disp(){
            var frames = pdaf_vert_Frame
            var i = 0
            // 初期化
            for(i = 0; i < frames.length ; i ++) {
                frames[i].changeMode(frames[i].mode_init)
            }
            // フォーカス設定
            var mode = frames[0].mode_green
            for(i = 0; i < root.focus_pdaf.length ; i ++) {
                var x = convToDispFrameX(root.focus_pdaf[i][0])
                var y = convToDispFrameY(root.focus_pdaf[i][1])
                frames[y].changeMode(mode)
            }
            pdaf_vert_Frame = frames
        }

        MouseArea {
            anchors.fill: parent
            onClicked:(mouse)=> {
                // PDAF枠表示中のフルエリア
                if((mode == afmode_fullarea) || (mode == afmode_fullarea_af) || (mode == afmode_fullareaf) || (mode == afmode_fullareaf_af)) {
                    var x_conv = parseInt( (mouse.x * 1000) / afframe.width )
                    var y_conv = parseInt( (mouse.y * 1000) / afframe.height )
                    if(deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) {
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_TRACKING_START(x_conv, y_conv);
                    } else {
                        var ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(x_conv, y_conv);
                        var ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(x_conv, y_conv);
                        var ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
                    }
                }
            }
        }
    }

    function initFrame() {
        pinpointZoom.initFrame()
    }

    // frame_pinpoint
    Rectangle {
        id: pinpointZoom

        readonly property real frameRatio: 0.25 // 0.3 // 2018/12/18 Panasonic Nakano; LiveView画像の横幅の1/4
        readonly property int marginValue: 10

        property real relativeW: 0
        property real relativeH: 0

        property real iniW: 0
        property real iniH: 0

        function initFrame() {
            var ratio = 0.75
            var aspect = deviceAdapter.pinpAspectRatio
            if(aspect > LT.Utilities.PINPAR_Error &&
               aspect !== LT.Utilities.PINPAR_Multi){
                switch(deviceAdapter.pinpAspectRatio){
                case LT.Utilities.PINPAR_4_3:
                    ratio = 4/3
                    break;
                case LT.Utilities.PINPAR_3_2:
                    ratio = 3/2
                    break;
                case LT.Utilities.PINPAR_16_9:
                    ratio = 16/9
                    break;
                case LT.Utilities.PINPAR_1_1:
                    ratio = 1
                    break;
                case LT.Utilities.PINPAR_C4K:
                    ratio = 17/9
                    break;
                case LT.Utilities.PINPAR_7_5:
                    ratio = 7/5
                    break;
                case LT.Utilities.PINPAR_3_1:
                    ratio = 3
                    break;
                case LT.Utilities.PINPAR_65_24:
                    ratio = 65/24
                    break;
                case LT.Utilities.PINPAR_2_1:
                    ratio = 2
                    break;
                case LT.Utilities.PINPAR_5_3:
                    ratio = 5/3
                    break;
                case LT.Utilities.PINPAR_2_4_1:
                    ratio = 2.4
                    break;
                default:
                    break;
                }
            }else{
                // クリエイティブ動画の場合
                if(deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Movie){
                    var numberOfQuality = deviceAdapter.mov_quality_list_number_of_quality()
                    for (var i = 0; i < numberOfQuality; i++) {
                        var quality_mode = deviceAdapter.mov_quality_list_data_video_quality(i)
                        if (quality_mode === deviceAdapter.recMovie) {
                            var px_val = deviceAdapter.mov_quality_list_data_pixels(i)
                            var aspect = utilities.getAspectRatioFromMoviePixel(px_val)
                            switch(aspect){
                            case LT.Utilities.AR_4_3:
                                ratio = 4/3
                                break;
                            case LT.Utilities.AR_3_2:
                                ratio = 3/2
                                break;
                            case LT.Utilities.AR_16_9:
                                ratio = 16/9
                                break;
                            case LT.Utilities.AR_1_1:
                                ratio = 1
                                break;
                            case LT.Utilities.AR_17_9:
                                ratio = 17/9
                                break;
                            case LT.Utilities.AR_7_5:
                                ratio = 7/5
                                break;
                            case LT.Utilities.AR_3_1:
                                ratio = 3
                                break;
                            case LT.Utilities.AR_65_24:
                                ratio = 65/24
                                break;
                            case LT.Utilities.AR_2_1:
                                ratio = 2
                                break;
                            default:
                                break;
                            }
                            
                            break
                        }
                    }
                }else{
                    switch(deviceAdapter.aspectRatio) {
                    case LT.DeviceAdapter.AR_Nomal_4_3:         //AR_Nomal_4_3
                        ratio = 4/3
                        break;
                    case LT.DeviceAdapter.AR_Film_3_2:          //AR_Film_3_2
                        ratio = 3/2
                        break;
                    case LT.DeviceAdapter.AR_Hdtv_16_9:         //AR_Hdtv_16_9
                        ratio = 16/9
                        break;
                    case LT.DeviceAdapter.AR_Blog_1_1:          //AR_Blog_1_1
                        ratio = 1
                        break;
                    case LT.DeviceAdapter.AR_2_1:
                        ratio = 2;
                        break;
                    case LT.DeviceAdapter.AR_65_24:
                        ratio = 65/24;
                        break;
                    case LT.DeviceAdapter.AR_Unknown:
                    case LT.DeviceAdapter.AR_Multi_MULTI:       //AR_Multi_MULTI
                    case LT.DeviceAdapter.AR_Cinema_4k:         //AR_Cinema_4k
                    case LT.DeviceAdapter.AR_7_5:               //AR_7_5
                    case LT.DeviceAdapter.AR_3_1:               //AR_3_1
                    case LT.DeviceAdapter.AR_Check:             //AR_Check
                    default:
                        break;
                    }
                }
            }

            if (imageLV.paintedWidth < imageLV.paintedHeight) {
                // pinpointZoom.width = imageLV.paintedWidth*frameRatio
                // pinpointZoom.height = pinpointZoom.width/ratio
                pinpointZoom.height = imageLV.paintedHeight * frameRatio    // 2018/12/18 Panasonic Nakano
                pinpointZoom.width = pinpointZoom.height * ratio            // 2018/12/18 Panasonic Nakano
            } else {
                // pinpointZoom.height = imageLV.paintedHeight*frameRatio
                // pinpointZoom.width = pinpointZoom.height*ratio
                pinpointZoom.width = imageLV.paintedWidth * frameRatio  // 2018/12/18 Panasonic Nakano
                pinpointZoom.height = pinpointZoom.width / ratio        // 2018/12/18 Panasonic Nakano
            }

            iniW = imageLV.paintedWidth
            iniH = imageLV.paintedHeight

            relativeW = pinpointZoom.width / imageLV.paintedWidth
            relativeH = pinpointZoom.height / imageLV.paintedHeight
        }

        function mag_frame_move_pos(tempx, tempy) {

            var posX = tempx*(1000/pinpointZoom.width)
            var posY = tempy*(1000/pinpointZoom.height)

            /* クリックされたら AF枠設定APIを呼ぶ*/
            var ret = magnify_pos_set(posX, posY)

            LTSubFunction.console_debug.out("mag_frame_move_pos: posX: " + posX + " posY: " + posY + " return:" + ret)
            return ret
        }

        anchors {
            top: parent.top
            right: parent.right
            margins: pinpointZoom.marginValue
        }

        color: "#77777777"
        border.color:LTSubFunction.afFrameColorPalette.green//"green"

        onVisibleChanged: {
            if (pinpointZoom.visible) {
                initFrame()
            }
        }

        Connections {
            target:imageLV

            function onSourceSizeChanged() {
                if (imageLV.paintedWidth < imageLV.paintedHeight) {
                    pinpointZoom.relativeH *= ((imageLV.paintedWidth / imageLV.paintedHeight) *
                                               (pinpointZoom.iniH / pinpointZoom.iniW))

                } else {
                    pinpointZoom.relativeW *= ((imageLV.paintedHeight / imageLV.paintedWidth) *
                                               (pinpointZoom.iniW / pinpointZoom.iniH))
                }

                pinpointZoom.iniW = imageLV.paintedWidth
                pinpointZoom.iniH = imageLV.paintedHeight

                pinpointZoom.width = imageLV.paintedWidth * pinpointZoom.relativeH
                pinpointZoom.height = imageLV.paintedHeight * pinpointZoom.relativeH
            }

            function onPaintedWidthChanged() {
                pinpointZoom.width = imageLV.paintedWidth * pinpointZoom.relativeW

            }

            function onPaintedHeightChanged() {
                pinpointZoom.height = imageLV.paintedHeight * pinpointZoom.relativeH
            }
        }

        MouseArea {
            id: ppZoomMsArea
            anchors.fill: parent

            onClicked: {
                pinpointZoom.mag_frame_move_pos(mouseX, mouseY)
            }
        }

        Rectangle {
            id: pinpointFrame

            property real relativeX: 0
            property real relativeY: 0
            property real relativeW: 0
            property real relativeH: 0

            property real minX: 0
            property real maxX: 0
            property real minY: 0
            property real maxY: 0

            function minDragX() {
                var ret = (pinpointFrame.minX * pinpointZoom.width)/1000 - pinpointFrame.width/2
                return ret;
            }

            function minDragY() {
                var ret = (pinpointFrame.minY * pinpointZoom.height)/1000 - pinpointFrame.height/2
                return ret;
            }

            function maxDragX() {
                var ret = (pinpointFrame.maxX * pinpointZoom.width)/1000 - pinpointFrame.width/2
                return ret;
            }

            function maxDragY() {
                var ret = (pinpointFrame.maxY * pinpointZoom.height)/1000 - pinpointFrame.height/2
                return ret;
            }

            color:"transparent"
            border.color:LTSubFunction.afFrameColorPalette.yellow//"yellow"

            Drag.active: ppMsArea.drag.active

            onXChanged: {
                relativeX = x / pinpointZoom.width
            }

            onYChanged: {
                relativeY = y / pinpointZoom.height
            }

            onWidthChanged: {
                relativeW = width / pinpointZoom.width
            }

            onHeightChanged: {
                relativeH = height / pinpointZoom.height
            }

            onMinXChanged: {
                ppMsArea.drag.minimumX = pinpointFrame.minDragX()
            }

            onMaxXChanged: {
                ppMsArea.drag.maximumX = pinpointFrame.maxDragX()
            }

            onMinYChanged: {
                ppMsArea.drag.minimumY = pinpointFrame.minDragY()
            }

            onMaxYChanged: {
                ppMsArea.drag.maximumY = pinpointFrame.maxDragY()
            }

            MouseArea {
                id: ppMsArea
                anchors.fill: parent

                drag {
                    target: {
                        if (afaeStartFlg
                            && (mode != afmode_mfz && mode != afmode_pinpointz && mode != afmode_lvmag_z)) {
                            return null
                        } else {
                            return pinpointFrame
                        }
                    }

                    minimumX: pinpointFrame.minDragX()
                    maximumX: pinpointFrame.maxDragX()
                    minimumY: pinpointFrame.minDragY()
                    maximumY: pinpointFrame.maxDragY()
                }

                onPositionChanged: {
//                    var point = pinpointFrame.mapToItem(pinpointZoom, pinpointFrame.width/2, pinpointFrame.height/2)
//                    pinpointZoom.mag_frame_move_pos(point.x, point.y)
                }

                // 押した時のイベントに変更  AF枠表示
                onReleased: {
                    var point = pinpointFrame.mapToItem(pinpointZoom, pinpointFrame.width/2, pinpointFrame.height/2)
                    pinpointZoom.mag_frame_move_pos(point.x, point.y)
                }
            }

            Connections {
                target: pinpointZoom

                function onWidthChanged() {
                    pinpointFrame.x = pinpointZoom.width * pinpointFrame.relativeX
                    pinpointFrame.width = pinpointZoom.width * pinpointFrame.relativeW

                    ppMsArea.drag.minimumX = pinpointFrame.minDragX()
                    ppMsArea.drag.maximumX = pinpointFrame.maxDragX()
                }
                function onHeightChanged() {
                    pinpointFrame.y = pinpointZoom.height * pinpointFrame.relativeY
                    pinpointFrame.height = pinpointZoom.height * pinpointFrame.relativeH

                    ppMsArea.drag.minimumY = pinpointFrame.minDragY()
                    ppMsArea.drag.maximumY = pinpointFrame.maxDragY()
                }
            }
        }

    }

    // 外枠
    // サイズ・位置は315点基準。
    LTAFFrameZoneOuter {
        id: zone_outer
        readonly property int x_sep: 0
        readonly property int y_sep: 0
        x: calc_margin_x() - zone_outer.lineSize
        y: calc_margin_y() - zone_outer.lineSize
        width: areaWidth + (zone_outer.lineSize * 2)
        height: areaHeight + (zone_outer.lineSize * 2)
        visible: false
        // 四角枠の行列数、幅、高さ
        frame_x_num: getFrame315SplitNumX()
        frame_y_num: getFrame315SplitNumY()
        frame_width: (areaWidth / frame_x_num) - x_sep
        frame_height: (areaHeight / frame_y_num) - y_sep
        // 枠設定範囲の幅、高さ
        property int areaWidth: root.width - 2*calc_margin_x()
        property int areaHeight: root.height - 2*calc_margin_y()
        property int minX: 0
        property int minY: 0
        property int maxX: 0
        property int maxY: 0

        // afframeからの左右の余白サイズ
        function calc_margin_x() {
            return parseInt((getFrame315MarginH() * root.width) / getFrame315ResolutionX())
        }
        // afframeからの上下の余白サイズ
        function calc_margin_y() {
            return parseInt((getFrame315MarginV() * root.height) / getFrame315ResolutionY())
        }

        // f225_x_max*f225_y_maxの枠座標からf225_x_num*f225_y_numの枠座標に変換
        function convToDispFrameX(in_x) {
            return in_x - (root.frame315SplitMaxNumX - getFrame315SplitNumX())/2
        }
        function convToDispFrameY(in_y) {
            return in_y - (root.frame315SplitMaxNumY - getFrame315SplitNumY())/2
        }

        function afmode_customf_mouse_click(mouse_x, mouse_y) {
            //LTSubFunction.console_debug.out("afmode_customf_mouse_click autoFocusMode=" + deviceAdapter.autoFocusMode)
            // 外枠を除いた位置で計算
            var in_mouse_x = Math.max(0, mouse_x - zone_outer.lineSize)
            var in_mouse_y = Math.max(0, mouse_y - zone_outer.lineSize)
            in_mouse_x = Math.min(zone_outer.width - zone_outer.lineSize, in_mouse_x)
            in_mouse_y = Math.min(zone_outer.height - zone_outer.lineSize, in_mouse_y)
            var width1 = areaWidth / getFrame315SplitNumX()
            var height1 = areaHeight / getFrame315SplitNumY()
            var width2 = width1 - x_sep
            var height2 = height1 - y_sep
            var v_f225_pos_x = Math.min(parseInt(in_mouse_x/width2), getFrame315SplitNumX()-1)
            var v_f225_pos_y = Math.min(parseInt(in_mouse_y/height2), getFrame315SplitNumY()-1)
            // 外枠が領域外に表示されないように選択枠を調整
            var ajust_x = Math.max(v_f225_pos_x, parseInt((maxX - minX) / 2))
            var ajust_y = Math.max(v_f225_pos_y, parseInt((maxY - minY) / 2))
            ajust_x = Math.min(ajust_x, (getFrame315SplitNumX() - 1) - parseInt((maxX - minX) / 2))
            ajust_y = Math.min(ajust_y, (getFrame315SplitNumY() - 1) - parseInt((maxY - minY) / 2))
            // 座標計算
            var x_before = (width2 * ajust_x) + calc_margin_x() + (width2/2)
            var y_before = (height2 * ajust_y) + calc_margin_y() + (height2/2)
            // カメラ内のスケール(1000スケール)に変換
            var v_center_x = parseInt( (x_before * 1000) / afframe.width )
            var v_center_y = parseInt( (y_before * 1000) / afframe.height )
            var ret1 = LT.DeviceAdapter.Ternary_False
            var ret2 = LT.DeviceAdapter.Ternary_True
            var ret3 = LT.DeviceAdapter.Ternary_True
            if( (deviceAdapter.afFrame_pos_X != v_center_x) || (deviceAdapter.afFrame_pos_Y != v_center_y)) {
                deviceAdapter.afFrame_pos_X = v_center_x;     // 1点 X座標
                deviceAdapter.afFrame_pos_Y = v_center_y;     // 1点 Y座標
                ret1 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Start(v_center_x, v_center_y);
                ret2 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_Move(v_center_x, v_center_y);
                ret3 = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_Area_End();
            }
            if((ret1==LT.DeviceAdapter.Ternary_True)&&(ret2==LT.DeviceAdapter.Ternary_True)&&(ret3==LT.DeviceAdapter.Ternary_True)) {
            } else {
                return LT.DeviceAdapter.Ternary_False;
            }
        }

        // 外枠の中心座標を計算
        function zone_center_disp() {
            // zone_outerの中心X座標を計算
            var idx = (zone_outer.minX + parseInt(((zone_outer.maxX+1) - zone_outer.minX)/2))
            var x_before = zone_outer.calc_margin_x() + idx*zone_outer.frame_width + zone_outer.frame_width/2
            // zone_outerの中心Y座標を計算
            idx = (zone_outer.minY + parseInt(((zone_outer.maxY+1) - zone_outer.minY)/2))
            var y_before = zone_outer.calc_margin_y() + idx*zone_outer.frame_height + zone_outer.frame_height/2
            // カメラ内のスケール(1000スケール)に変換
            var v_center_x = parseInt( (x_before * 1000) / afframe.width )
            var v_center_y = parseInt( (y_before * 1000) / afframe.height )
            root.center_x = v_center_x
            root.center_y = v_center_y
        }
        
        function afmode_custom_disp() {
            // 四角枠の初期化
            afframe225.disp_clear()
            afframePDAF.disp_clear()
            
            // 選択AF枠を囲う矩形の座標（左上・右下）を求める
            minX = getFrame315SplitNumX()
            minY = getFrame315SplitNumY()
            maxX = 0
            maxY = 0
            for(var i = 0; i < root.custom_frame.length; i++) {
                var x = convToDispFrameX(root.custom_frame[i][0])
                var y = convToDispFrameY(root.custom_frame[i][1])
                if( ((0 <= x) && (x < getFrame315SplitNumX())) && ((0 <= y) && (y < getFrame315SplitNumY())) ) {
                    minX = Math.min(minX, x)
                    minY = Math.min(minY, y)
                    maxX = Math.max(maxX, x)
                    maxY = Math.max(maxY, y)
                }
            }
            // 中心座標計算
            zone_center_disp()
            
            // サイズ設定
            zone_outer.changeSize((maxX+1)-minX, (maxY+1)-minY)
            // 位置設定
            zone_outer.changeCord(minX, minY)
            // モード設定
            switch(deviceAdapter.autoFocusMode) {
            case LT.Utilities.AFM_CustomVertical:
            case LT.Utilities.AFM_CustomHorizon:
            case LT.Utilities.AFM_VertHori:
                if(((maxX+1) - minX) < ((maxY+1) - minY)) {
                    // 縦
                    if(deviceAdapter.afPDAFEnable) {
                        zone_outer.changeMode(zone_outer.afmode_outer_vert_pdaf)
                    }else{
                        zone_outer.changeMode(zone_outer.afmode_outer_vert)
                    }
                } else {
                    // 横
                    if(deviceAdapter.afPDAFEnable) {
                        zone_outer.changeMode(zone_outer.afmode_outer_hori_pdaf)
                    }else{
                        zone_outer.changeMode(zone_outer.afmode_outer_hori)
                    }
                }
                break
            case LT.Utilities.AFM_CustomCenter:
            case LT.Utilities.AFM_Ellipse:
                zone_outer.changeMode(zone_outer.afmode_outer_ellipse)
                break
            default:
                zone_outer.changeMode(zone_outer.afmode_outer_init)
                break
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked:(mouse)=> {
                LTSubFunction.console_debug.out("zone_outer onClicked mode="+mode)
                if( (mode == afmode_customo) || (mode == afmode_customof) || (mode == afmode_customo_af) || (mode == afmode_customof_af) ) {
                    //LTSubFunction.console_debug.out("zone_outer custom")
                    zone_outer.afmode_customf_mouse_click(mouse.x, mouse.y)
                }
            }
        }

        onFrame_widthChanged: {
            if( (mode == afmode_customo) || (mode == afmode_customof) || (mode == afmode_customo_af) || (mode == afmode_customof_af) ) {
                // AF枠サイズ変更時、外枠のサイズ・位置を再計算
                afmode_custom_disp()
            }
        }
        onFrame_heightChanged: {
            if( (mode == afmode_customo) || (mode == afmode_customof) || (mode == afmode_customo_af) || (mode == afmode_customof_af) ) {
                // AF枠サイズ変更時、外枠のサイズ・位置を再計算
                afmode_custom_disp()
            }
        }

    }

    // center plus 2023/06  十字アイコンずれ修正 parseInt -> Math.round
    Item {
        id: center_plus
        Rectangle {
            id: center_plus_rect1
            x: {
                if(root.center_keep) {
                    Math.round(500 * afframe.width / 1000) - Math.round(center_plus_rect1.width / 2)
                } else {
                    Math.round(root.center_x * afframe.width / 1000) - Math.round(center_plus_rect1.width / 2)
                }
            }
            y: {
                if(root.center_keep) {
                    Math.round(500 * afframe.height / 1000) - Math.round(center_plus_rect1.height / 2)
                } else {
                    Math.round(root.center_y * afframe.height / 1000) - Math.round(center_plus_rect1.height / 2)
                }
            }
            width: Math.ceil((20 * afframe.width / getFrame225ResolutionX()) / 2 ) * 2
            height: 4
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: center_plus_rect2
            x: {
                if(root.center_keep) {
                    Math.round(500 * afframe.width / 1000) - Math.round(center_plus_rect2.width / 2)
                } else {
                    Math.round(root.center_x * afframe.width / 1000) - Math.round(center_plus_rect2.width / 2)
                }
            }
            y: {
                if(root.center_keep) {
                    Math.round(500 * afframe.height / 1000) - Math.round(center_plus_rect2.height / 2)
                } else {
                    Math.round(root.center_y * afframe.height / 1000) - Math.round(center_plus_rect2.height / 2)
                }
            }
            width: 4
            height: center_plus_rect1.width
            border.width: 1
            border.color: "black"
            color: center_plus_rect1.color
        }
        Rectangle {
            id: center_plus_rect3
            x: center_plus_rect1.x + 1
            y: center_plus_rect1.y + 1
            width: center_plus_rect1.width - 2
            height: 2
            color: center_plus_rect1.color
        }
        Rectangle {
            id: center_plus_rect4
            x: center_plus_rect2.x + 1
            y: center_plus_rect2.y + 1
            width: 2
            height: center_plus_rect3.width
            color: center_plus_rect1.color
        }
        Rectangle {
            id: center_plus_rect5
            x: center_plus_rect1.x
            y: center_plus_rect1.y
            width: 4
            height: 4
            border.width: 1
            border.color: "black"
            visible: false
            color: LTSubFunction.afFrameColorPalette.white
        }
        Rectangle {
            id: center_plus_rect6
            x: center_plus_rect1.x + center_plus_rect1.width - center_plus_rect6.width
            y: center_plus_rect1.y
            width: 4
            height: 4
            border.width: 1
            border.color: "black"
            visible: center_plus_rect5.visible
            color:  center_plus_rect5.color
        }
        Rectangle {
            id: center_plus_rect7
            x: center_plus_rect2.x
            y: center_plus_rect2.y
            width: 4
            height: 4
            border.width: 1
            border.color: "black"
            visible: center_plus_rect5.visible
            color: center_plus_rect5.color
        }
        Rectangle {
            id: center_plus_rect8
            x: center_plus_rect2.x
            y: center_plus_rect2.y + center_plus_rect2.height - center_plus_rect8.height
            width: 4
            height: 4
            border.width: 1
            border.color: "black"
            visible: center_plus_rect5.visible
            color: center_plus_rect5.color
        }
        function set_center_blue() {
            center_plus_rect1.color = LTSubFunction.afFrameColorPalette.lightBlue//"#00FFFF"
            center_plus_rect5.visible = false
        }
        function set_center_blues() {
            center_plus_rect1.color = LTSubFunction.afFrameColorPalette.lightBlue//"#00FFFF"
            center_plus_rect5.visible = true
            //AF枠色指定対応
            //十字の外側にちょっとはみ出る部分は色が変わる
            center_plus_rect5.color = LTSubFunction.getAfFrameColor()
        }
        function set_center_white() {
            //AF枠色指定対応
            //白の場合は設定値の色取得してみる
            center_plus_rect1.color = LTSubFunction.getAfFrameColor()//"#FFFFFF"
            center_plus_rect5.visible = false
        }
        function set_center_green() {
            center_plus_rect1.color = LTSubFunction.afFrameColorPalette.green//"green"
            center_plus_rect5.visible = false
        }
        function set_center_red() {
            center_plus_rect1.color = LTSubFunction.afFrameColorPalette.red//"#FF0000"
            center_plus_rect5.visible = false
        }
    }

    // frame_small
    // ポイントスコープ設定で「全画面」のときに使用する
    LTAFFrameSmall {
        id: small_frame

        x: 0                    //  デフォルトの設定が意味ないので すべて 0 に設定
        y: 0
        width: 0
        height: 0
    }

    // frame_drag
    LTAFFrameDrag {
        id: frame_drag

        onVisibleChanged: {
            frame_drag.dragFrameUpdate()
        }

        anchors.fill: parent
    }
}
