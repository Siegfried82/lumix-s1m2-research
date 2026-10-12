package com.panasonic.jp.lumixlab.controller.fragment;

/* JADX INFO: loaded from: classes2.dex */
public class FirmwareUpdateDetailFragment extends p281z5.D<D5.E1> implements R5.a {

    /* JADX INFO: renamed from: J0, reason: collision with root package name */
    public static final androidx.lifecycle.M f17637J0 = null;

    /* JADX INFO: renamed from: A0, reason: collision with root package name */
    public p281z5.C2490f4 f17638A0;

    /* JADX INFO: renamed from: B0, reason: collision with root package name */
    public p281z5.C2460c4 f17639B0;

    /* JADX INFO: renamed from: C0, reason: collision with root package name */
    public boolean f17640C0;

    /* JADX INFO: renamed from: D0, reason: collision with root package name */
    public java.lang.String f17641D0;

    /* JADX INFO: renamed from: E0, reason: collision with root package name */
    public boolean f17642E0;

    /* JADX INFO: renamed from: F0, reason: collision with root package name */
    public java.lang.String f17643F0;

    /* JADX INFO: renamed from: G0, reason: collision with root package name */
    public boolean f17644G0;

    /* JADX INFO: renamed from: H0, reason: collision with root package name */
    public p281z5.C2570n4 f17645H0;

    /* JADX INFO: renamed from: I0, reason: collision with root package name */
    public final p281z5.C2530j4 f17646I0;

    /* JADX INFO: renamed from: k0, reason: collision with root package name */
    public p281z5.InterfaceC2580o4 f17647k0;

    /* JADX INFO: renamed from: l0, reason: collision with root package name */
    public R5.h f17648l0;

    /* JADX INFO: renamed from: m0, reason: collision with root package name */
    public java.util.List f17649m0;

    /* JADX INFO: renamed from: n0, reason: collision with root package name */
    public int f17650n0;

    /* JADX INFO: renamed from: o0, reason: collision with root package name */
    public int f17651o0;

    /* JADX INFO: renamed from: p0, reason: collision with root package name */
    public java.lang.String f17652p0;

    /* JADX INFO: renamed from: q0, reason: collision with root package name */
    public boolean f17653q0;

    /* JADX INFO: renamed from: r0, reason: collision with root package name */
    public p281z5.C2550l4 f17654r0;

    /* JADX INFO: renamed from: s0, reason: collision with root package name */
    public p281z5.W3 f17655s0;

    /* JADX INFO: renamed from: t0, reason: collision with root package name */
    public int f17656t0;

    /* JADX INFO: renamed from: u0, reason: collision with root package name */
    public java.io.File f17657u0;

    /* JADX INFO: renamed from: v0, reason: collision with root package name */
    public long f17658v0;

    /* JADX INFO: renamed from: w0, reason: collision with root package name */
    public int f17659w0;

    /* JADX INFO: renamed from: x0, reason: collision with root package name */
    public int f17660x0;

    /* JADX INFO: renamed from: y0, reason: collision with root package name */
    public p281z5.C2538k2 f17661y0;

    /* JADX INFO: renamed from: z0, reason: collision with root package name */
    public java.lang.String f17662z0;

    static {
            androidx.lifecycle.M r0 = new androidx.lifecycle.M
            java.lang.String r1 = "UPDATE_DEVICE_DETAIL"
            r0.<init>(r1)
            com.panasonic.jp.lumixlab.controller.fragment.FirmwareUpdateDetailFragment.f17637J0 = r0
            return
    }

    public FirmwareUpdateDetailFragment() {
            r2 = this;
            r2.<init>()
            r0 = -1
            r2.f17650n0 = r0
            r2.f17651o0 = r0
            java.lang.String r0 = ""
            r2.f17652p0 = r0
            r1 = 1
            r2.f17653q0 = r1
            r1 = 0
            r2.f17659w0 = r1
            r2.f17660x0 = r1
            r2.f17640C0 = r1
            r2.f17641D0 = r0
            r2.f17642E0 = r1
            r2.f17644G0 = r1
            z5.j4 r0 = new z5.j4
            r0.<init>(r2)
            r2.f17646I0 = r0
            return
    }

    public static java.lang.String t0(java.lang.String r1) {
            java.lang.String r0 = "Ver."
            boolean r0 = r1.contains(r0)
            if (r0 == 0) goto Ld
            r0 = 4
            java.lang.String r1 = r1.substring(r0)
        Ld:
            return r1
    }

    public static boolean v0() {
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            int r0 = r0.getFirmwareOperationState()
            r1 = 3
            if (r1 == r0) goto L19
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            int r0 = r0.getFirmwareOperationState()
            r1 = 4
            if (r1 != r0) goto L17
            goto L19
        L17:
            r0 = 0
            goto L1a
        L19:
            r0 = 1
        L1a:
            return r0
    }

    public final void A0() {
            r3 = this;
            z5.c4 r0 = r3.f17639B0
            if (r0 != 0) goto Lc
            z5.c4 r0 = new z5.c4
            r0.<init>()
            r3.f17639B0 = r0
            goto L13
        Lc:
            boolean r0 = r0.isAdded()
            if (r0 == 0) goto L13
            return
        L13:
            z5.c4 r0 = r3.f17639B0
            androidx.fragment.app.A0 r1 = r3.getChildFragmentManager()
            r2 = 2132018364(0x7f1404bc, float:1.9675033E38)
            java.lang.String r2 = r3.getString(r2)
            r0.showNow(r1, r2)
            z5.c4 r0 = r3.f17639B0
            z5.m4 r1 = new z5.m4
            r1.<init>(r3)
            r0.f31352Z = r1
            return
    }

    public final void B0(boolean r4) {
            r3 = this;
            if (r4 == 0) goto L4a
            K5.o r4 = r3.s0()
            if (r4 == 0) goto L4a
            K5.g r0 = K5.EnumC0627g.BLE_STATE_CONNECTED
            K5.g r1 = r4.f8328i
            boolean r0 = r0.equals(r1)
            if (r0 == 0) goto L4a
            K5.n r0 = K5.EnumC0641n.WIFI_CONNECTED
            K5.n r1 = r4.f8331l
            boolean r0 = r0.equals(r1)
            if (r0 == 0) goto L4b
            java.lang.Boolean r4 = r4.f8324e
            boolean r4 = r4.booleanValue()
            if (r4 == 0) goto L4b
            r4 = 2132017643(0x7f1401eb, float:1.967357E38)
            java.lang.String r4 = r3.getString(r4)
            z5.W3 r0 = r3.f17655s0
            if (r0 != 0) goto L37
            z5.W3 r0 = new z5.W3
            r0.<init>()
            r3.f17655s0 = r0
            goto L3e
        L37:
            boolean r0 = r0.isAdded()
            if (r0 == 0) goto L3e
            goto L49
        L3e:
            z5.W3 r0 = r3.f17655s0
            r0.f31190y = r4
            androidx.fragment.app.A0 r3 = r3.getChildFragmentManager()
            r0.showNow(r3, r4)
        L49:
            return
        L4a:
            r0 = 0
        L4b:
            z5.f4 r4 = r3.f17638A0
            if (r4 != 0) goto L57
            z5.f4 r4 = new z5.f4
            r4.<init>()
            r3.f17638A0 = r4
            goto L5e
        L57:
            boolean r4 = r4.isAdded()
            if (r4 == 0) goto L5e
            return
        L5e:
            boolean r4 = com.panasonic.jp.lumixlab.util.K0.a()
            z5.f4 r1 = r3.f17638A0
            java.lang.Boolean r2 = com.panasonic.jp.lumixlab.util.C1410v.f18182a
            com.panasonic.jp.lumixlab.LlcApplication r2 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            int r2 = r2.getFupWarningNoticeVersionCode()
            if (r4 == 0) goto La0
            r4 = 1
            if (r2 <= r4) goto La0
            java.lang.String r4 = com.panasonic.jp.lumixlab.util.C1410v.E()
            com.panasonic.jp.lumixlab.LlcApplication r2 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            java.util.Map r2 = r2.getFUPWarningNoticeMap()
            java.lang.Object r4 = r2.get(r4)
            java.lang.String r4 = (java.lang.String) r4
            boolean r2 = android.text.TextUtils.isEmpty(r4)
            if (r2 != 0) goto L91
            java.lang.String r2 = "https://panasonic.jp/support/share/eww/com/software/lumix_lab/"
            java.lang.String r4 = B9.AbstractC0105t.n(r2, r4)
        L91:
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r2 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r2)
            monitor-exit(r2)
            boolean r2 = android.text.TextUtils.isEmpty(r4)
            if (r2 == 0) goto La4
            java.lang.String r4 = com.panasonic.jp.lumixlab.util.C1410v.e0()
            goto La4
        La0:
            java.lang.String r4 = com.panasonic.jp.lumixlab.util.C1410v.e0()
        La4:
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r2 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r2)
            monitor-exit(r2)
            r1.f31420y = r4
            z5.f4 r4 = r3.f17638A0
            r4.f31417V = r0
            androidx.fragment.app.A0 r0 = r3.getChildFragmentManager()
            r1 = 2132018364(0x7f1404bc, float:1.9675033E38)
            java.lang.String r1 = r3.getString(r1)
            r4.showNow(r0, r1)
            z5.f4 r4 = r3.f17638A0
            z5.h4 r0 = new z5.h4
            r0.<init>(r3)
            r4.f31419X = r0
            return
    }

    public final void C0(boolean r3) {
            r2 = this;
            z5.v4 r0 = new z5.v4
            r0.<init>()
            com.panasonic.jp.lumixlab.util.P r1 = new com.panasonic.jp.lumixlab.util.P
            r1.<init>(r2, r3)
            r0.f31893y = r1
            androidx.fragment.app.A0 r3 = r2.getChildFragmentManager()
            r1 = 2132017385(0x7f1400e9, float:1.9673047E38)
            java.lang.String r2 = r2.getString(r1)
            r0.showNow(r3, r2)
            return
    }

    @Override // p281z5.D
    public final R1.a O(android.view.LayoutInflater r1, android.view.ViewGroup r2) {
            r0 = this;
            D5.E1 r0 = D5.E1.a(r1, r2)
            return r0
    }

    @Override // p281z5.D
    public final void Q() {
            r8 = this;
            R5.h r0 = r8.f17648l0
            if (r0 != 0) goto Lb
            R5.h r0 = new R5.h
            r0.<init>()
            r8.f17648l0 = r0
        Lb:
            android.os.Bundle r0 = r8.getArguments()
            if (r0 == 0) goto Laa
            android.os.Bundle r0 = r8.getArguments()
            java.lang.String r1 = "backPage"
            java.lang.String r0 = r0.getString(r1)
            r8.f17652p0 = r0
            android.os.Bundle r0 = r8.getArguments()
            java.lang.String r1 = "name"
            java.lang.String r0 = r0.getString(r1)
            android.os.Bundle r1 = r8.getArguments()
            java.lang.String r2 = "version"
            java.lang.String r1 = r1.getString(r2)
            java.lang.String r2 = r8.f17652p0
            com.panasonic.jp.lumixlab.LlcApplication r3 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            java.util.List r3 = r3.getUpdateInfoEntityList()
            r8.f17649m0 = r3
            r3 = 0
        L3e:
            java.util.List r4 = r8.f17649m0
            int r4 = r4.size()
            if (r3 >= r4) goto Laa
            java.util.List r4 = r8.f17649m0
            java.lang.Object r4 = r4.get(r3)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r4 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r4
            java.lang.String r5 = r4.getUpdateDeviceCode()
            java.lang.String r6 = "notifyActivity"
            boolean r6 = android.text.TextUtils.equals(r2, r6)
            if (r6 == 0) goto L5e
            java.lang.String r5 = r4.getUpdateName()
        L5e:
            int r6 = r4.getUpdateDeviceType()
            if (r6 != 0) goto L80
            java.lang.String r6 = r4.getUpdateName()
            boolean r6 = android.text.TextUtils.equals(r6, r0)
            if (r6 == 0) goto L80
            java.lang.String r6 = r4.getUpdateVersion()
            java.lang.String r6 = t0(r6)
            java.lang.String r7 = t0(r1)
            boolean r6 = android.text.TextUtils.equals(r6, r7)
            if (r6 != 0) goto L9f
        L80:
            int r6 = r4.getUpdateDeviceType()
            r7 = 1
            if (r6 != r7) goto La7
            boolean r5 = android.text.TextUtils.equals(r5, r0)
            if (r5 == 0) goto La7
            java.lang.String r4 = r4.getUpdateVersion()
            java.lang.String r4 = t0(r4)
            java.lang.String r5 = t0(r1)
            boolean r4 = android.text.TextUtils.equals(r4, r5)
            if (r4 == 0) goto La7
        L9f:
            r8.f17650n0 = r3
            java.lang.String r0 = "UPDATE_DEVICE_DETAIL"
            r8.z0(r0)
            goto Laa
        La7:
            int r3 = r3 + 1
            goto L3e
        Laa:
            androidx.lifecycle.M r0 = com.panasonic.jp.lumixlab.controller.fragment.FirmwareUpdateDetailFragment.f17637J0
            androidx.lifecycle.A r1 = r8.getViewLifecycleOwner()
            com.panasonic.jp.lumixlab.widget.d r2 = new com.panasonic.jp.lumixlab.widget.d
            r3 = 9
            r2.<init>(r8, r3)
            r0.e(r1, r2)
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            z5.k2 r0 = r0.cameraViewModel
            r8.f17661y0 = r0
            K5.o r0 = r8.s0()
            if (r0 == 0) goto Lcc
            java.lang.String r0 = r0.f8340u
            r8.f17662z0 = r0
        Lcc:
            return
    }

    @Override // p281z5.D
    public final void R() {
            r3 = this;
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.u2 r0 = r0.f2973f
            android.widget.TextView r0 = r0.f4654e
            z5.i4 r1 = new z5.i4
            r2 = 0
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.u2 r0 = r0.f2973f
            android.widget.Button r0 = r0.f4652c
            z5.i4 r1 = new z5.i4
            r2 = 1
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.u2 r0 = r0.f2973f
            android.widget.Button r0 = r0.f4651b
            z5.i4 r1 = new z5.i4
            r2 = 2
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.s2 r0 = r0.f2971d
            android.widget.Button r0 = r0.f4523b
            z5.i4 r1 = new z5.i4
            r2 = 3
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.t2 r0 = r0.f2972e
            android.widget.Button r0 = r0.f4622c
            z5.i4 r1 = new z5.i4
            r2 = 4
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.t2 r0 = r0.f2972e
            android.widget.Button r0 = r0.f4621b
            z5.i4 r1 = new z5.i4
            r2 = 5
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.v2 r0 = r0.f2974g
            android.widget.Button r0 = r0.f4712b
            z5.i4 r1 = new z5.i4
            r2 = 6
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.w2 r0 = r0.f2975h
            android.widget.Button r0 = r0.f4748b
            z5.i4 r1 = new z5.i4
            r2 = 7
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            R1.a r0 = r3.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.w2 r0 = r0.f2975h
            android.widget.Button r0 = r0.f4749c
            z5.i4 r1 = new z5.i4
            r2 = 8
            r1.<init>(r3, r2)
            r0.setOnClickListener(r1)
            return
    }

    @Override // p281z5.D
    public final void S() {
            r2 = this;
            z5.n4 r0 = new z5.n4
            r0.<init>(r2)
            r2.f17645H0 = r0
            java.lang.String r0 = "BROADCAST_ACTION_SD_CARD_STATUS"
            android.content.IntentFilter r0 = com.adobe.marketing.mobile.c.g(r0)
            android.content.Context r1 = r2.requireContext()
            w0.d r1 = p243w0.d.a(r1)
            z5.n4 r2 = r2.f17645H0
            r1.b(r0, r2)
            return
    }

    @Override // p281z5.D
    public final void f0(boolean r2) {
            r1 = this;
            R1.a r0 = r1.f30774x
            if (r0 == 0) goto L7
            r1.y0(r2)
        L7:
            return
    }

    public final void o0() {
            r3 = this;
            java.lang.String r0 = r3.f17652p0
            java.lang.String r1 = "notifyActivity"
            boolean r0 = android.text.TextUtils.equals(r0, r1)
            if (r0 == 0) goto L1d
            androidx.fragment.app.T r3 = r3.requireActivity()
            com.panasonic.jp.lumixlab.controller.activity.FirmwareDetailActivity r3 = (com.panasonic.jp.lumixlab.controller.activity.FirmwareDetailActivity) r3
            r3.getClass()
            r0 = 205(0xcd, float:2.87E-43)
            r3.setResult(r0)
            r3.finish()
            goto L97
        L1d:
            java.lang.String r0 = "community"
            java.lang.String r1 = r3.f17652p0
            boolean r0 = r0.equals(r1)
            if (r0 == 0) goto L77
            androidx.fragment.app.N r3 = r3.getParentFragment()
            if (r3 == 0) goto L97
            boolean r0 = r3 instanceof p281z5.C2459c3
            if (r0 == 0) goto L97
            z5.c3 r3 = (p281z5.C2459c3) r3
            java.lang.String r0 = "FIRMWARE_UPDATE_LIST"
            androidx.fragment.app.A0 r1 = r3.f31344k0
            if (r1 != 0) goto L3f
            androidx.fragment.app.A0 r1 = r3.getChildFragmentManager()
            r3.f31344k0 = r1
        L3f:
            androidx.fragment.app.A0 r1 = r3.f31344k0     // Catch: java.lang.Exception -> L72
            androidx.fragment.app.N r0 = r1.C(r0)     // Catch: java.lang.Exception -> L72
            if (r0 == 0) goto L6c
            boolean r1 = r0 instanceof com.panasonic.jp.lumixlab.controller.fragment.FirmwareUpdateListFragment     // Catch: java.lang.Exception -> L72
            if (r1 == 0) goto L6c
            com.panasonic.jp.lumixlab.controller.fragment.FirmwareUpdateListFragment r0 = (com.panasonic.jp.lumixlab.controller.fragment.FirmwareUpdateListFragment) r0     // Catch: java.lang.Exception -> L72
            java.util.List r1 = r0.f17665m0     // Catch: java.lang.Exception -> L72
            boolean r1 = r1.isEmpty()     // Catch: java.lang.Exception -> L72
            if (r1 == 0) goto L5b
            java.lang.String r1 = "UPDATE_DEVICE_NO"
            r0.r0(r1)     // Catch: java.lang.Exception -> L72
            goto L6c
        L5b:
            int r1 = r0.f17667o0     // Catch: java.lang.Exception -> L72
            java.util.List r2 = r0.f17665m0     // Catch: java.lang.Exception -> L72
            int r2 = r2.size()     // Catch: java.lang.Exception -> L72
            if (r1 >= r2) goto L6c
            e5.V0 r1 = r0.f17666n0     // Catch: java.lang.Exception -> L72
            int r0 = r0.f17667o0     // Catch: java.lang.Exception -> L72
            r1.e(r0)     // Catch: java.lang.Exception -> L72
        L6c:
            androidx.fragment.app.A0 r3 = r3.f31344k0     // Catch: java.lang.Exception -> L72
            r3.N()     // Catch: java.lang.Exception -> L72
            goto L97
        L72:
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r3 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r3)
            monitor-exit(r3)
            goto L97
        L77:
            x1.L r0 = androidx.navigation.fragment.NavHostFragment.F(r3)
            r0.m()
            java.lang.String r0 = r3.f17652p0
            java.lang.String r1 = "notifyDialogFragment"
            boolean r0 = android.text.TextUtils.equals(r0, r1)
            if (r0 == 0) goto L97
            androidx.fragment.app.T r3 = r3.requireActivity()
            r0 = 2131363684(0x7f0a0764, float:1.8347184E38)
            android.view.View r3 = r3.findViewById(r0)
            r0 = 0
            r3.setVisibility(r0)
        L97:
            return
    }

    @Override // p281z5.D, androidx.fragment.app.N
    public final void onAttach(android.content.Context r1) {
            r0 = this;
            super.onAttach(r1)
            z5.o4 r1 = (p281z5.InterfaceC2580o4) r1
            r0.f17647k0 = r1
            return
    }

    @Override // p281z5.D, androidx.fragment.app.N
    public final void onDestroyView() {
            r2 = this;
            z5.n4 r0 = r2.f17645H0
            if (r0 == 0) goto L11
            android.content.Context r0 = r2.requireContext()
            w0.d r0 = p243w0.d.a(r0)
            z5.n4 r1 = r2.f17645H0
            r0.d(r1)
        L11:
            super.onDestroyView()
            return
    }

    @Override // p281z5.D, androidx.fragment.app.N
    public final void onPause() {
            r1 = this;
            super.onPause()
            r0 = 1
            r1.f17640C0 = r0
            z5.l4 r0 = r1.f17654r0
            if (r0 == 0) goto L17
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            w0.d r0 = p243w0.d.a(r0)
            z5.l4 r1 = r1.f17654r0
            r0.d(r1)
        L17:
            return
    }

    @Override // p281z5.D, androidx.fragment.app.N
    public final void onResume() {
            r2 = this;
            super.onResume()
            boolean r0 = r2.f17640C0
            if (r0 == 0) goto L18
            boolean r0 = r2.f17642E0
            if (r0 == 0) goto L18
            java.lang.String r0 = r2.f17641D0
            boolean r0 = android.text.TextUtils.isEmpty(r0)
            if (r0 != 0) goto L18
            java.lang.String r0 = r2.f17641D0
            r2.p0(r0)
        L18:
            r0 = 0
            r2.f17640C0 = r0
            java.lang.String r1 = ""
            r2.f17641D0 = r1
            r2.f17642E0 = r0
            z5.l4 r0 = new z5.l4
            r0.<init>(r2)
            r2.f17654r0 = r0
            java.lang.String r0 = "BROADCAST_ACTION_FIRMWARE_GO_DOWNLOAD"
            android.content.IntentFilter r0 = com.adobe.marketing.mobile.c.g(r0)
            com.panasonic.jp.lumixlab.LlcApplication r1 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            w0.d r1 = p243w0.d.a(r1)
            z5.l4 r2 = r2.f17654r0
            r1.b(r0, r2)
            return
    }

    public final void p0(java.lang.String r4) {
            r3 = this;
            android.os.Handler r0 = com.panasonic.jp.lumixlab.LlcApplication.mainHandler
            z5.g3 r1 = new z5.g3
            r2 = 1
            r1.<init>(r2, r3, r4)
            r0.post(r1)
            return
    }

    public final void q0() {
            r3 = this;
            R1.a r0 = r3.f30774x
            if (r0 == 0) goto L38
            r0 = 0
            r3.f17660x0 = r0
            r3.f17653q0 = r0
            boolean r1 = r3.f17644G0
            if (r1 == 0) goto L10
            r3.f17644G0 = r0
            goto L1a
        L10:
            r1 = 2132017631(0x7f1401df, float:1.9673546E38)
            java.lang.String r1 = r3.getString(r1)
            r3.p0(r1)
        L1a:
            com.panasonic.jp.lumixlab.LlcApplication r1 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            int r1 = r1.getFirmwareOperationState()
            r2 = 3
            if (r2 != r1) goto L31
            java.util.concurrent.ExecutorService r0 = com.panasonic.jp.lumixlab.LlcApplication.executor
            z5.g4 r1 = new z5.g4
            r2 = 5
            r1.<init>(r3, r2)
            r0.execute(r1)
            goto L38
        L31:
            com.panasonic.jp.lumixlab.LlcApplication r3 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            r3.setFirmwareOperationState(r0)
        L38:
            return
    }

    public final void r0(int r4, java.lang.String r5) {
            r3 = this;
            R1.a r0 = r3.f30774x
            if (r0 == 0) goto L64
            r0 = 200(0xc8, float:2.8E-43)
            r1 = 0
            if (r4 != r0) goto L2e
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r4 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r4)
            monitor-exit(r4)
            int r4 = r3.f17660x0
            int r4 = r4 + 1
            r3.f17660x0 = r4
            int r5 = r3.f17659w0
            if (r4 >= r5) goto L1f
            boolean r0 = r3.f17653q0
            if (r0 == 0) goto L1f
            r3.x0()
            goto L64
        L1f:
            if (r4 != r5) goto L64
            com.panasonic.jp.lumixlab.LlcApplication r4 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            r4.setFirmwareOperationState(r1)
            java.lang.String r4 = "DETAIL_TRANSFERRED"
            r3.z0(r4)
            goto L64
        L2e:
            boolean r4 = v0()
            if (r4 == 0) goto L38
            r3.w0()
            goto L64
        L38:
            z5.k2 r4 = r3.f17661y0
            if (r4 == 0) goto L52
            com.panasonic.jp.lumixlab.LlcApplication r4 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            int r4 = r4.getFirmwareOperationState()
            r0 = 2
            if (r0 != r4) goto L52
            java.util.concurrent.ExecutorService r4 = com.panasonic.jp.lumixlab.LlcApplication.executor
            z5.g4 r0 = new z5.g4
            r2 = 4
            r0.<init>(r3, r2)
            r4.execute(r0)
        L52:
            com.panasonic.jp.lumixlab.LlcApplication r4 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            r4.setFirmwareOperationState(r1)
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r4 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r4)
            monitor-exit(r4)
            r3.f17660x0 = r1
            r3.f17653q0 = r1
            r3.p0(r5)
        L64:
            return
    }

    public final K5.C0643o s0() {
            r3 = this;
            z5.k2 r0 = r3.f17661y0
            r1 = 0
            if (r0 == 0) goto L34
            int r2 = r0.f31569E
            r0.getClass()
            androidx.lifecycle.M r0 = p281z5.C2538k2.f31564S
            java.lang.Object r0 = r0.d()
            if (r0 == 0) goto L34
            z5.k2 r3 = r3.f17661y0
            r3.getClass()
            androidx.lifecycle.M r3 = p281z5.C2538k2.f31564S
            java.lang.Object r3 = r3.d()
            java.util.List r3 = (java.util.List) r3
            if (r3 == 0) goto L34
            boolean r0 = r3.isEmpty()
            if (r0 != 0) goto L34
            int r0 = r3.size()
            if (r2 >= r0) goto L34
            java.lang.Object r3 = r3.get(r2)
            K5.o r3 = (K5.C0643o) r3
            return r3
        L34:
            return r1
    }

    public final void u0(java.lang.String r17, boolean r18) {
            r16 = this;
            r4 = r16
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            z5.k2 r0 = r0.cameraViewModel
            r0.getClass()
            androidx.lifecycle.M r0 = p281z5.C2538k2.f31564S
            java.lang.Object r0 = r0.d()
            r1 = 1
            r2 = 0
            r5 = 7
            r6 = 6
            r7 = 5
            r8 = 2
            r10 = 3
            r11 = 4
            r12 = 0
            if (r0 == 0) goto L42
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            boolean r0 = r0.isUsbReady()
            if (r0 == 0) goto L34
            com.panasonic.jp.lumixlab.LlcApplication r0 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            boolean r0 = r0.isPtpConnected()
            if (r0 == 0) goto L34
            r0 = 10
            goto L11d
        L34:
            androidx.lifecycle.M r0 = p281z5.C2538k2.f31564S
            java.lang.Object r0 = r0.d()
            java.util.ArrayList r0 = (java.util.ArrayList) r0
            boolean r0 = r0.isEmpty()
            if (r0 == 0) goto L45
        L42:
            r0 = r1
            goto L11d
        L45:
            int r0 = r4.f17650n0
            java.util.List r14 = r4.f17649m0
            boolean r14 = r14.isEmpty()
            if (r14 != 0) goto L60
            java.util.List r14 = r4.f17649m0
            int r14 = r14.size()
            if (r0 >= r14) goto L60
            java.util.List r14 = r4.f17649m0
            java.lang.Object r0 = r14.get(r0)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r0 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r0
            goto L61
        L60:
            r0 = r2
        L61:
            if (r0 == 0) goto L11b
            r14 = r12
        L64:
            androidx.lifecycle.M r15 = p281z5.C2538k2.f31564S
            java.lang.Object r15 = r15.d()
            java.util.ArrayList r15 = (java.util.ArrayList) r15
            int r15 = r15.size()
            r13 = -1
            if (r14 >= r15) goto La8
            androidx.lifecycle.M r15 = p281z5.C2538k2.f31564S
            java.lang.Object r15 = r15.d()
            java.util.ArrayList r15 = (java.util.ArrayList) r15
            java.lang.Object r15 = r15.get(r14)
            K5.o r15 = (K5.C0643o) r15
            K5.g r9 = K5.EnumC0627g.BLE_STATE_CONNECTED
            K5.g r3 = r15.f8328i
            if (r9 != r3) goto La5
            java.lang.String r3 = r0.getUpdateDeviceCode()
            java.lang.String r9 = r15.f8327h
            boolean r3 = android.text.TextUtils.equals(r3, r9)
            if (r3 != 0) goto La3
            java.lang.String r3 = r0.getUpdateName()
            java.lang.String r9 = r15.f8312A
            boolean r3 = android.text.TextUtils.equals(r3, r9)
            if (r3 == 0) goto La0
            goto La3
        La0:
            r3 = r1
        La1:
            r14 = r13
            goto Laa
        La3:
            r3 = r1
            goto Laa
        La5:
            int r14 = r14 + 1
            goto L64
        La8:
            r3 = r12
            goto La1
        Laa:
            if (r3 == 0) goto L42
            if (r14 != r13) goto Lba
            int r0 = r0.getUpdateDeviceType()
            if (r0 != 0) goto Lb7
            r0 = r10
            goto L11d
        Lb7:
            r0 = r11
            goto L11d
        Lba:
            androidx.lifecycle.M r3 = p281z5.C2538k2.f31564S
            java.lang.Object r3 = r3.d()
            java.util.ArrayList r3 = (java.util.ArrayList) r3
            java.lang.Object r3 = r3.get(r14)
            K5.o r3 = (K5.C0643o) r3
            int r9 = r0.getUpdateDeviceType()
            if (r9 != 0) goto Ld9
            java.lang.String r9 = r3.f8341v
            java.lang.String r14 = r0.getUpdateVersion()
            int r9 = com.panasonic.jp.lumixlab.util.C1410v.Y(r9, r14)
            goto Le3
        Ld9:
            java.lang.String r9 = r3.f8344y
            java.lang.String r14 = r0.getUpdateVersion()
            int r9 = com.panasonic.jp.lumixlab.util.C1410v.Y(r9, r14)
        Le3:
            if (r9 >= 0) goto L104
            java.lang.String r9 = r3.f8344y
            java.lang.String r0 = r0.getUpdateRequiredVersion()
            int r0 = com.panasonic.jp.lumixlab.util.C1410v.j(r9, r0)
            if (r13 >= r0) goto L101
            boolean r0 = com.panasonic.jp.lumixlab.util.C1388j0.a(r11)
            if (r0 == 0) goto L101
            K5.n r0 = K5.EnumC0641n.WIFI_CONNECTED
            K5.n r3 = r3.f8331l
            if (r0 != r3) goto Lff
            r0 = r12
            goto L11d
        Lff:
            r0 = r8
            goto L11d
        L101:
            r0 = 9
            goto L11d
        L104:
            if (r9 != 0) goto L110
            int r0 = r0.getUpdateDeviceType()
            if (r0 != 0) goto L10e
            r0 = r7
            goto L11d
        L10e:
            r0 = r6
            goto L11d
        L110:
            int r0 = r0.getUpdateDeviceType()
            if (r0 != 0) goto L118
            r0 = r5
            goto L11d
        L118:
            r0 = 8
            goto L11d
        L11b:
            r0 = 99
        L11d:
            r3 = 2132017653(0x7f1401f5, float:1.967359E38)
            if (r0 != 0) goto L170
            if (r18 == 0) goto L16b
            r4.y0(r1)
            K5.o r0 = r16.s0()
            int r1 = r4.f17650n0
            java.util.List r5 = r4.f17649m0
            boolean r5 = r5.isEmpty()
            if (r5 != 0) goto L147
            java.util.List r5 = r4.f17649m0
            int r5 = r5.size()
            if (r1 >= r5) goto L147
            java.util.List r2 = r4.f17649m0
            java.lang.Object r1 = r2.get(r1)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r1 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r1
            r5 = r1
            goto L148
        L147:
            r5 = r2
        L148:
            if (r0 == 0) goto L162
            if (r5 == 0) goto L162
            java.util.concurrent.ExecutorService r6 = com.panasonic.jp.lumixlab.LlcApplication.executor
            Y5.h r7 = new Y5.h
            r8 = 6
            r0 = r7
            r1 = r16
            r2 = r17
            r3 = r5
            r4 = r16
            r5 = r8
            r0.<init>(r1, r2, r3, r4, r5)
            r6.execute(r7)
            goto L278
        L162:
            java.lang.String r0 = r4.getString(r3)
            r4.p0(r0)
            goto L278
        L16b:
            r16.A0()
            goto L278
        L170:
            if (r0 != r1) goto L197
            z5.i8 r0 = new z5.i8
            r0.<init>()
            android.content.res.Resources r1 = r16.getResources()
            r2 = 2132017616(0x7f1401d0, float:1.9673515E38)
            java.lang.String r1 = r1.getString(r2)
            z5.h4 r2 = new z5.h4
            r2.<init>(r4)
            java.lang.String r3 = ""
            r0.N(r3, r1, r2)
            androidx.fragment.app.A0 r1 = r16.getChildFragmentManager()
            java.lang.String r2 = "LUT_PHONE_NOTICE_DIALOG_FRAGMENT"
            r0.showNow(r1, r2)
            goto L278
        L197:
            if (r0 != r8) goto L202
            java.lang.String r0 = r4.f17652p0
            java.lang.String r3 = "community"
            boolean r0 = r3.equals(r0)
            java.lang.String r5 = "BUNDLE_KEY_BACK_DESTINATION"
            java.lang.String r6 = "BUNDLE_KEY_DESTINATION"
            java.lang.String r7 = "firmware_detail"
            if (r0 == 0) goto L1eb
            androidx.fragment.app.N r0 = r16.getParentFragment()
            if (r0 == 0) goto L278
            boolean r8 = r0 instanceof p281z5.C2459c3
            if (r8 == 0) goto L278
            z5.c3 r0 = (p281z5.C2459c3) r0
            androidx.fragment.app.A0 r8 = r0.f31344k0
            if (r8 != 0) goto L1bf
            androidx.fragment.app.A0 r8 = r0.getChildFragmentManager()
            r0.f31344k0 = r8
        L1bf:
            androidx.fragment.app.A0 r0 = r0.f31344k0
            androidx.fragment.app.a r0 = B9.AbstractC0105t.f(r0, r0)
            com.panasonic.jp.lumixlab.controller.fragment.CameraWifiConnectFragment r8 = new com.panasonic.jp.lumixlab.controller.fragment.CameraWifiConnectFragment
            r8.<init>()
            android.os.Bundle r9 = new android.os.Bundle
            r9.<init>()
            r9.putString(r6, r7)
            r9.putString(r5, r3)
            r8.setArguments(r9)
            r0.l(r4)
            r3 = 2131362552(0x7f0a02f8, float:1.8344888E38)
            r0.f(r3, r8, r2, r1)
            java.lang.String r1 = "WIFI_CONNECT"
            r0.d(r1)
            r0.i(r12)
            goto L278
        L1eb:
            android.os.Bundle r0 = new android.os.Bundle
            r0.<init>()
            r0.putString(r6, r7)
            r0.putString(r5, r7)
            x1.L r1 = androidx.navigation.fragment.NavHostFragment.F(r16)
            r3 = 2131361878(0x7f0a0056, float:1.834352E38)
            r1.k(r3, r2, r0)
            goto L278
        L202:
            if (r0 != r10) goto L210
            r0 = 2132017647(0x7f1401ef, float:1.9673578E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L210:
            if (r0 != r11) goto L21d
            r0 = 2132017646(0x7f1401ee, float:1.9673576E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L21d:
            if (r0 != r7) goto L22a
            r0 = 2132017651(0x7f1401f3, float:1.9673586E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L22a:
            if (r0 != r6) goto L237
            r0 = 2132017650(0x7f1401f2, float:1.9673584E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L237:
            if (r0 != r5) goto L244
            r0 = 2132017636(0x7f1401e4, float:1.9673556E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L244:
            r1 = 8
            if (r0 != r1) goto L253
            r0 = 2132017652(0x7f1401f4, float:1.9673588E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L253:
            r1 = 9
            if (r0 != r1) goto L262
            r0 = 2132017654(0x7f1401f6, float:1.9673593E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L262:
            r1 = 10
            if (r0 != r1) goto L271
            r0 = 2132017644(0x7f1401ec, float:1.9673572E38)
            java.lang.String r0 = r4.getString(r0)
            r4.p0(r0)
            goto L278
        L271:
            java.lang.String r0 = r4.getString(r3)
            r4.p0(r0)
        L278:
            return
    }

    public final void w0() {
            r5 = this;
            r0 = 0
            r5.f17653q0 = r0
            R5.h r0 = r5.f17648l0
            r0.getClass()
            java.lang.String r1 = "https://"
            com.panasonic.jp.lumixlab.LlcApplication r2 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            java.lang.String r2 = r2.getAuthToken()
            java.lang.String r3 = I5.c.d()     // Catch: java.lang.Exception -> L4f
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r4 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r4)     // Catch: java.lang.Exception -> L4f
            monitor-exit(r4)     // Catch: java.lang.Exception -> L4f
            java.lang.StringBuilder r4 = new java.lang.StringBuilder     // Catch: java.lang.Exception -> L4f
            r4.<init>(r1)     // Catch: java.lang.Exception -> L4f
            r4.append(r3)     // Catch: java.lang.Exception -> L4f
            java.lang.String r1 = "/"
            r4.append(r1)     // Catch: java.lang.Exception -> L4f
            java.lang.String r1 = r4.toString()     // Catch: java.lang.Exception -> L4f
            p084h6.b.f22722a = r1     // Catch: java.lang.Exception -> L4f
            h6.h r1 = p084h6.h.a()     // Catch: java.lang.Exception -> L4f
            r1.getClass()     // Catch: java.lang.Exception -> L4f
            oa.v0 r1 = p084h6.h.l()     // Catch: java.lang.Exception -> L4f
            java.lang.Object r1 = r1.b()     // Catch: java.lang.Exception -> L4f
            h6.a r1 = (p084h6.a) r1     // Catch: java.lang.Exception -> L4f
            java.lang.String r2 = com.panasonic.jp.lumixlab.util.C1410v.J(r2)     // Catch: java.lang.Exception -> L4f
            oa.h r1 = r1.g(r2)     // Catch: java.lang.Exception -> L4f
            R5.g r2 = new R5.g     // Catch: java.lang.Exception -> L4f
            r2.<init>(r0, r5)     // Catch: java.lang.Exception -> L4f
            r1.z(r2)     // Catch: java.lang.Exception -> L4f
            goto L52
        L4f:
            r5.q0()
        L52:
            return
    }

    public final void x0() {
            r10 = this;
            int r0 = r10.f17660x0
            float r0 = (float) r0
            int r1 = r10.f17659w0
            float r1 = (float) r1
            float r0 = r0 / r1
            r1 = 1120403456(0x42c80000, float:100.0)
            float r0 = r0 * r1
            int r0 = (int) r0
            R1.a r1 = r10.f30774x
            D5.E1 r1 = (D5.E1) r1
            D5.s2 r1 = r1.f2971d
            android.widget.ProgressBar r1 = r1.f4524c
            r1.setProgress(r0)
            R1.a r1 = r10.f30774x
            D5.E1 r1 = (D5.E1) r1
            D5.s2 r1 = r1.f2971d
            android.widget.TextView r1 = r1.f4525d
            r2 = 2132017692(0x7f14021c, float:1.967367E38)
            java.lang.String r2 = r10.getString(r2)
            java.lang.StringBuilder r3 = new java.lang.StringBuilder
            r3.<init>()
            r3.append(r0)
            java.lang.String r0 = "%"
            r3.append(r0)
            java.lang.String r0 = r3.toString()
            java.lang.Object[] r0 = new java.lang.Object[]{r0}
            java.lang.String r0 = java.lang.String.format(r2, r0)
            r1.setText(r0)
            int r0 = r10.f17660x0
            int r1 = r10.f17656t0
            int r2 = r0 * r1
            long r3 = r10.f17658v0
            int r0 = r0 + 1
            long r5 = (long) r0
            long r0 = (long) r1
            long r5 = r5 * r0
            long r0 = java.lang.Math.min(r3, r5)
            int r0 = (int) r0
            int r0 = r0 - r2
            byte[] r1 = new byte[r0]
            java.io.FileInputStream r3 = new java.io.FileInputStream     // Catch: java.lang.Exception -> L9b
            java.io.File r4 = r10.f17657u0     // Catch: java.lang.Exception -> L9b
            r3.<init>(r4)     // Catch: java.lang.Exception -> L9b
            long r4 = (long) r2     // Catch: java.lang.Exception -> L9b
            r3.skip(r4)     // Catch: java.lang.Exception -> L9b
            r3.read(r1)     // Catch: java.lang.Exception -> L9b
            r3.close()     // Catch: java.lang.Exception -> L9b
            boolean r2 = v0()     // Catch: java.lang.Exception -> L9b
            if (r2 == 0) goto L71
            r10.w0()     // Catch: java.lang.Exception -> L9b
            goto Lb4
        L71:
            g8.z0 r2 = p076g8.A0.f21885a     // Catch: java.lang.Exception -> L9b
            r2.getClass()     // Catch: java.lang.Exception -> L9b
            r2 = 0
            r3 = 0
            g8.y0 r7 = p076g8.z0.a(r2, r3, r1, r0)     // Catch: java.lang.Exception -> L9b
            R5.h r4 = r10.f17648l0     // Catch: java.lang.Exception -> L9b
            java.lang.String r5 = java.lang.String.valueOf(r0)     // Catch: java.lang.Exception -> L9b
            int r0 = r10.f17660x0     // Catch: java.lang.Exception -> L9b
            java.lang.String r6 = java.lang.String.valueOf(r0)     // Catch: java.lang.Exception -> L9b
            java.util.List r0 = r10.f17649m0     // Catch: java.lang.Exception -> L9b
            int r1 = r10.f17650n0     // Catch: java.lang.Exception -> L9b
            java.lang.Object r0 = r0.get(r1)     // Catch: java.lang.Exception -> L9b
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r0 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r0     // Catch: java.lang.Exception -> L9b
            int r8 = r0.getUpdateDeviceType()     // Catch: java.lang.Exception -> L9b
            r9 = r10
            r4.b(r5, r6, r7, r8, r9)     // Catch: java.lang.Exception -> L9b
            goto Lb4
        L9b:
            boolean r0 = v0()
            if (r0 == 0) goto La5
            r10.w0()
            goto Lb4
        La5:
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r0 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r0)
            monitor-exit(r0)
            r0 = 2132017638(0x7f1401e6, float:1.967356E38)
            java.lang.String r0 = r10.getString(r0)
            r1 = -1
            r10.r0(r1, r0)
        Lb4:
            return
    }

    public final void y0(boolean r3) {
            r2 = this;
            R1.a r0 = r2.f30774x
            D5.E1 r0 = (D5.E1) r0
            android.widget.RelativeLayout r0 = r0.f2976i
            if (r3 == 0) goto La
            r1 = 0
            goto Lc
        La:
            r1 = 8
        Lc:
            r0.setVisibility(r1)
            if (r3 == 0) goto L1b
            R1.a r2 = r2.f30774x
            D5.E1 r2 = (D5.E1) r2
            android.widget.RelativeLayout r2 = r2.f2976i
            r3 = 0
            r2.setOnClickListener(r3)
        L1b:
            return
    }

    public final void z0(java.lang.String r18) {
            r17 = this;
            r0 = r17
            r1 = r18
            r4 = 2
            r5 = 5
            r6 = -1
            r7 = 1
            r8 = 0
            r0.f17643F0 = r1
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.r2 r9 = r9.f2970c
            android.widget.LinearLayout r9 = r9.f4403a
            r10 = 8
            r9.setVisibility(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.u2 r9 = r9.f2973f
            android.widget.LinearLayout r9 = r9.f4650a
            r9.setVisibility(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.s2 r9 = r9.f2971d
            android.widget.LinearLayout r9 = r9.f4522a
            r9.setVisibility(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.t2 r9 = r9.f2972e
            android.widget.LinearLayout r9 = r9.f4620a
            r9.setVisibility(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.v2 r9 = r9.f2974g
            android.widget.LinearLayout r9 = r9.f4711a
            r9.setVisibility(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.w2 r9 = r9.f2975h
            android.widget.LinearLayout r9 = r9.f4747a
            r9.setVisibility(r10)
            int r9 = r18.hashCode()
            switch(r9) {
                case -1798584887: goto L8f;
                case -1301367486: goto L84;
                case -473661000: goto L79;
                case -274320028: goto L6e;
                case 323989324: goto L63;
                case 841735125: goto L58;
                default: goto L56;
            }
        L56:
            r9 = r6
            goto L99
        L58:
            java.lang.String r9 = "DETAIL_DOWNLOADED"
            boolean r9 = r1.equals(r9)
            if (r9 != 0) goto L61
            goto L56
        L61:
            r9 = r5
            goto L99
        L63:
            java.lang.String r9 = "DETAIL_DOWNLOADING"
            boolean r9 = r1.equals(r9)
            if (r9 != 0) goto L6c
            goto L56
        L6c:
            r9 = 4
            goto L99
        L6e:
            java.lang.String r9 = "UPDATE_DEVICE_DETAIL"
            boolean r9 = r1.equals(r9)
            if (r9 != 0) goto L77
            goto L56
        L77:
            r9 = 3
            goto L99
        L79:
            java.lang.String r9 = "DETAIL_TRANSFERRED"
            boolean r9 = r1.equals(r9)
            if (r9 != 0) goto L82
            goto L56
        L82:
            r9 = r4
            goto L99
        L84:
            java.lang.String r9 = "DETAIL_TRANSFERRED_DELETE_CONFIRMATION"
            boolean r9 = r1.equals(r9)
            if (r9 != 0) goto L8d
            goto L56
        L8d:
            r9 = r7
            goto L99
        L8f:
            java.lang.String r9 = "DETAIL_TRANSFERRING"
            boolean r9 = r1.equals(r9)
            if (r9 != 0) goto L98
            goto L56
        L98:
            r9 = r8
        L99:
            switch(r9) {
                case 0: goto L13b;
                case 1: goto L124;
                case 2: goto L111;
                case 3: goto Lb6;
                case 4: goto L13b;
                case 5: goto L9e;
                default: goto L9c;
            }
        L9c:
            goto L197
        L9e:
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.r2 r9 = r9.f2970c
            android.widget.LinearLayout r9 = r9.f4403a
            r9.setVisibility(r8)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.t2 r9 = r9.f2972e
            android.widget.LinearLayout r9 = r9.f4620a
            r9.setVisibility(r8)
            goto L197
        Lb6:
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.r2 r9 = r9.f2970c
            android.widget.LinearLayout r9 = r9.f4403a
            r9.setVisibility(r8)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.u2 r9 = r9.f2973f
            android.widget.TextView r9 = r9.f4654e
            z5.g4 r10 = new z5.g4
            r10.<init>(r0, r8)
            r9.post(r10)
            com.panasonic.jp.lumixlab.LlcApplication r9 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            java.util.List r9 = r9.getUpdateInfoEntityList()
            int r10 = r0.f17650n0
            java.lang.Object r9 = r9.get(r10)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r9 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r9
            java.lang.String r9 = r9.getUpdateDownloadPath()
            boolean r9 = android.text.TextUtils.isEmpty(r9)
            if (r9 != 0) goto L197
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.u2 r9 = r9.f2973f
            android.widget.Button r9 = r9.f4652c
            r10 = 2132017669(0x7f140205, float:1.9673623E38)
            java.lang.String r10 = r0.getString(r10)
            r9.setText(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.u2 r9 = r9.f2973f
            android.widget.TextView r9 = r9.f4653d
            r10 = 2132017621(0x7f1401d5, float:1.9673526E38)
            java.lang.String r10 = r0.getString(r10)
            r9.setText(r10)
            goto L197
        L111:
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.v2 r9 = r9.f2974g
            android.widget.LinearLayout r9 = r9.f4711a
            r9.setVisibility(r8)
            com.panasonic.jp.lumixlab.LlcApplication r9 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            r9.setFirmwareOperationState(r5)
            goto L197
        L124:
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.r2 r9 = r9.f2970c
            android.widget.LinearLayout r9 = r9.f4403a
            r9.setVisibility(r8)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.w2 r9 = r9.f2975h
            android.widget.LinearLayout r9 = r9.f4747a
            r9.setVisibility(r8)
            goto L197
        L13b:
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.r2 r9 = r9.f2970c
            android.widget.LinearLayout r9 = r9.f4403a
            r9.setVisibility(r8)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.s2 r9 = r9.f2971d
            android.widget.LinearLayout r9 = r9.f4522a
            r9.setVisibility(r8)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.s2 r9 = r9.f2971d
            android.widget.ProgressBar r9 = r9.f4524c
            r9.setProgress(r8)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.s2 r9 = r9.f2971d
            android.widget.TextView r9 = r9.f4525d
            r10 = 2132017692(0x7f14021c, float:1.967367E38)
            java.lang.String r10 = r0.getString(r10)
            java.lang.String r11 = "0%"
            java.lang.Object[] r11 = new java.lang.Object[]{r11}
            java.lang.String r10 = java.lang.String.format(r10, r11)
            r9.setText(r10)
            R1.a r9 = r0.f30774x
            D5.E1 r9 = (D5.E1) r9
            D5.s2 r9 = r9.f2971d
            android.widget.TextView r9 = r9.f4526e
            java.lang.String r10 = "DETAIL_DOWNLOADING"
            boolean r10 = r10.equals(r1)
            if (r10 == 0) goto L190
            r10 = 2132017628(0x7f1401dc, float:1.967354E38)
        L18b:
            java.lang.String r10 = r0.getString(r10)
            goto L194
        L190:
            r10 = 2132017680(0x7f140210, float:1.9673645E38)
            goto L18b
        L194:
            r9.setText(r10)
        L197:
            java.util.List r9 = r0.f17649m0
            int r10 = r0.f17650n0
            java.lang.Object r9 = r9.get(r10)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r9 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r9
            com.panasonic.jp.lumixlab.util.b0 r10 = com.panasonic.jp.lumixlab.util.C1368b0.H()
            java.lang.String r11 = "camera_image"
            java.lang.String r12 = r9.getUpdateDeviceThumbnailPath()
            java.lang.String r13 = ".jpg"
            r10.getClass()
            java.lang.String r10 = com.panasonic.jp.lumixlab.util.C1368b0.A(r11, r12, r13)
            java.io.File r11 = new java.io.File
            r11.<init>(r10)
            boolean r11 = r11.exists()
            if (r11 == 0) goto L1db
            R1.a r11 = r0.f30774x
            D5.E1 r11 = (D5.E1) r11
            android.widget.ImageView r11 = r11.f2969b
            com.panasonic.jp.lumixlab.util.b0 r12 = com.panasonic.jp.lumixlab.util.C1368b0.H()
            r12.getClass()
            com.panasonic.jp.lumixlab.util.W r13 = new com.panasonic.jp.lumixlab.util.W
            r14 = 0
            r13.<init>(r12, r6, r10, r14)
            com.panasonic.jp.lumixlab.util.X r10 = new com.panasonic.jp.lumixlab.util.X
            r10.<init>(r14, r11, r8)
            com.panasonic.jp.lumixlab.util.C1410v.x(r13, r10)
            goto L219
        L1db:
            com.panasonic.jp.lumixlab.LlcApplication r10 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            com.bumptech.glide.z r10 = com.bumptech.glide.c.c(r10)
            java.lang.StringBuilder r11 = new java.lang.StringBuilder
            java.lang.String r12 = "https://panasonic.jp/support/share/eww/com/software/lumix_lab/"
            r11.<init>(r12)
            java.lang.String r12 = r9.getUpdateDeviceThumbnailPath()
            r11.append(r12)
            java.lang.String r11 = r11.toString()
            V2.I r11 = com.panasonic.jp.lumixlab.util.C1407t0.b(r11)
            java.lang.Class<android.graphics.drawable.Drawable> r12 = android.graphics.drawable.Drawable.class
            com.bumptech.glide.v r10 = r10.a(r12)
            com.bumptech.glide.v r10 = r10.J(r11)
            R1.a r11 = r0.f30774x
            D5.E1 r11 = (D5.E1) r11
            android.widget.ImageView r11 = r11.f2969b
            r10.F(r11)
            java.lang.Thread r10 = new java.lang.Thread
            e5.S0 r11 = new e5.S0
            r11.<init>(r7, r9)
            r10.<init>(r11)
            r10.start()
        L219:
            R1.a r10 = r0.f30774x
            D5.E1 r10 = (D5.E1) r10
            D5.r2 r10 = r10.f2970c
            android.widget.TextView r10 = r10.f4405c
            java.lang.String r11 = r9.getUpdateName()
            r10.setText(r11)
            java.lang.String r10 = ""
            java.lang.String r11 = r9.getUpdateVersion()
            java.lang.String r12 = "Ver."
            boolean r11 = r11.contains(r12)
            if (r11 == 0) goto L23b
            java.lang.String r11 = r9.getUpdateVersion()
            goto L24d
        L23b:
            java.lang.StringBuilder r11 = new java.lang.StringBuilder
            java.lang.String r12 = "Ver."
            r11.<init>(r12)
            java.lang.String r12 = r9.getUpdateVersion()
            r11.append(r12)
            java.lang.String r11 = r11.toString()
        L24d:
            int r12 = r9.getUpdateDeviceType()
            if (r12 != r7) goto L257
            java.lang.String r11 = com.panasonic.jp.lumixlab.util.C1410v.B0(r11)
        L257:
            java.lang.String r12 = r9.getUpdateDate()
            java.lang.String r12 = com.panasonic.jp.lumixlab.util.C1410v.g(r12)
            java.lang.String r13 = r9.getUpdateSize()
            long r13 = java.lang.Long.parseLong(r13)
            double r13 = (double) r13
            r15 = 4697254411347427328(0x4130000000000000, double:1048576.0)
            double r13 = r13 / r15
            java.lang.Double r13 = java.lang.Double.valueOf(r13)
            java.lang.Object[] r13 = new java.lang.Object[]{r13}
            java.lang.String r14 = "%.2fMB"
            java.lang.String r13 = java.lang.String.format(r14, r13)
            java.lang.StringBuilder r14 = new java.lang.StringBuilder
            r14.<init>()
            r15 = 2132017658(0x7f1401fa, float:1.96736E38)
            java.lang.String r2 = r0.getString(r15)
            r14.append(r2)
            java.lang.String r2 = "：%s"
            r14.append(r2)
            java.lang.String r2 = java.lang.System.lineSeparator()
            r14.append(r2)
            r2 = 2132017656(0x7f1401f8, float:1.9673597E38)
            java.lang.String r3 = r0.getString(r2)
            r14.append(r3)
            java.lang.String r3 = "：%s"
            r14.append(r3)
            java.lang.String r3 = r14.toString()
            java.lang.StringBuilder r14 = new java.lang.StringBuilder
            r14.<init>()
            java.lang.String r15 = r0.getString(r15)
            r14.append(r15)
            java.lang.String r15 = "：%s"
            r14.append(r15)
            java.lang.String r15 = java.lang.System.lineSeparator()
            r14.append(r15)
            r15 = 2132017657(0x7f1401f9, float:1.9673599E38)
            java.lang.String r15 = r0.getString(r15)
            r14.append(r15)
            java.lang.String r15 = "：%s"
            r14.append(r15)
            java.lang.String r15 = java.lang.System.lineSeparator()
            r14.append(r15)
            java.lang.String r2 = r0.getString(r2)
            r14.append(r2)
            java.lang.String r2 = "：%s"
            r14.append(r2)
            java.lang.String r2 = r14.toString()
            java.lang.Object[] r14 = new java.lang.Object[]{r11, r12, r13}
            java.lang.String r14 = java.lang.String.format(r2, r14)
            int r15 = r18.hashCode()
            switch(r15) {
                case -1798584887: goto L32c;
                case -1301367486: goto L321;
                case -473661000: goto L316;
                case -274320028: goto L30b;
                case 323989324: goto L300;
                case 841735125: goto L2f5;
                default: goto L2f4;
            }
        L2f4:
            goto L336
        L2f5:
            java.lang.String r4 = "DETAIL_DOWNLOADED"
            boolean r1 = r1.equals(r4)
            if (r1 != 0) goto L2fe
            goto L336
        L2fe:
            r6 = r5
            goto L336
        L300:
            java.lang.String r4 = "DETAIL_DOWNLOADING"
            boolean r1 = r1.equals(r4)
            if (r1 != 0) goto L309
            goto L336
        L309:
            r6 = 4
            goto L336
        L30b:
            java.lang.String r4 = "UPDATE_DEVICE_DETAIL"
            boolean r1 = r1.equals(r4)
            if (r1 != 0) goto L314
            goto L336
        L314:
            r6 = 3
            goto L336
        L316:
            java.lang.String r5 = "DETAIL_TRANSFERRED"
            boolean r1 = r1.equals(r5)
            if (r1 != 0) goto L31f
            goto L336
        L31f:
            r6 = r4
            goto L336
        L321:
            java.lang.String r4 = "DETAIL_TRANSFERRED_DELETE_CONFIRMATION"
            boolean r1 = r1.equals(r4)
            if (r1 != 0) goto L32a
            goto L336
        L32a:
            r6 = r7
            goto L336
        L32c:
            java.lang.String r4 = "DETAIL_TRANSFERRING"
            boolean r1 = r1.equals(r4)
            if (r1 != 0) goto L335
            goto L336
        L335:
            r6 = r8
        L336:
            switch(r6) {
                case 0: goto L460;
                case 1: goto L41c;
                case 2: goto L414;
                case 3: goto L3bc;
                case 4: goto L367;
                case 5: goto L33b;
                default: goto L339;
            }
        L339:
            goto L471
        L33b:
            r1 = 2132017622(0x7f1401d6, float:1.9673528E38)
            java.lang.String r10 = r0.getString(r1)
            java.lang.Object[] r1 = new java.lang.Object[]{r11, r12, r13}
            java.lang.String r14 = java.lang.String.format(r2, r1)
            boolean r1 = com.panasonic.jp.lumixlab.util.C1367b.g()
            if (r1 == 0) goto L471
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r1 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r1)
            monitor-exit(r1)
            java.util.HashMap r1 = new java.util.HashMap
            r1.<init>()
            java.lang.String r2 = "ActionName"
            java.lang.String r3 = "FirmwareDownloadEnd"
            r1.put(r2, r3)
            java.lang.String r2 = "ファームウェアダウンロード完了画面"
            com.panasonic.jp.lumixlab.util.C1367b.j(r2, r1)
            goto L471
        L367:
            r0.f17651o0 = r8
            r1 = 2132017627(0x7f1401db, float:1.9673538E38)
            java.lang.String r10 = r0.getString(r1)
            java.lang.Object[] r1 = new java.lang.Object[]{r11, r13}
            java.lang.String r14 = java.lang.String.format(r3, r1)
            com.panasonic.jp.lumixlab.util.V.f17959b = r7
            R5.h r1 = r0.f17648l0
            java.lang.StringBuilder r2 = new java.lang.StringBuilder
            java.lang.String r3 = "https://panasonic.jp/support/share/eww/com/software/lumix_lab/"
            r2.<init>(r3)
            java.lang.String r3 = r9.getUpdateUrl()
            r2.append(r3)
            java.lang.String r2 = r2.toString()
            z5.j4 r3 = r0.f17646I0
            r1.getClass()
            h6.h r4 = p084h6.h.a()
            r4.getClass()
            oa.v0 r4 = p084h6.h.k()
            java.lang.Object r4 = r4.b()
            h6.a r4 = (p084h6.a) r4
            Y6.l r4 = r4.c(r2)
            Y6.r r5 = p184q7.i.f27169b
            h7.B r4 = r4.i(r5)
            h7.n r4 = r4.f(r5)
            R5.d r5 = new R5.d
            r5.<init>(r1, r3, r2)
            r4.d(r5)
            goto L471
        L3bc:
            int r1 = r0.f17650n0
            java.util.List r3 = r0.f17649m0
            int r3 = r3.size()
            if (r1 >= r3) goto L3e3
            java.util.List r1 = r0.f17649m0
            int r3 = r0.f17650n0
            java.lang.Object r1 = r1.get(r3)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r1 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r1
            java.lang.String r1 = r1.getUpdateDownloadPath()
            boolean r1 = android.text.TextUtils.isEmpty(r1)
            if (r1 != 0) goto L3e3
            r1 = 2132018364(0x7f1404bc, float:1.9675033E38)
            java.lang.String r1 = r0.getString(r1)
        L3e1:
            r10 = r1
            goto L3eb
        L3e3:
            r1 = 2132017625(0x7f1401d9, float:1.9673534E38)
            java.lang.String r1 = r0.getString(r1)
            goto L3e1
        L3eb:
            java.lang.Object[] r1 = new java.lang.Object[]{r11, r12, r13}
            java.lang.String r14 = java.lang.String.format(r2, r1)
            R5.h r1 = r0.f17648l0
            java.util.List r2 = r0.f17649m0
            int r3 = r0.f17650n0
            java.lang.Object r2 = r2.get(r3)
            com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity r2 = (com.panasonic.jp.lumixlab.database.entity.UpdateInfoEntity) r2
            long r2 = r2.getUpdateId()
            r1.getClass()
            java.lang.Thread r1 = new java.lang.Thread
            R5.c r4 = new R5.c
            r4.<init>(r2, r8)
            r1.<init>(r4)
            r1.start()
            goto L471
        L414:
            r1 = 2132017675(0x7f14020b, float:1.9673635E38)
            java.lang.String r10 = r0.getString(r1)
            goto L471
        L41c:
            r1 = 2132017674(0x7f14020a, float:1.9673633E38)
            java.lang.String r10 = r0.getString(r1)
            java.lang.Object[] r1 = new java.lang.Object[]{r11, r13}
            java.lang.String r14 = java.lang.String.format(r3, r1)
            int r1 = r9.getUpdateDeviceType()
            if (r1 != 0) goto L43b
            com.panasonic.jp.lumixlab.LlcApplication r1 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            java.lang.String r2 = ""
            r1.setLensName(r2)
            goto L444
        L43b:
            com.panasonic.jp.lumixlab.LlcApplication r1 = com.panasonic.jp.lumixlab.LlcApplication.getContext()
            java.lang.String r2 = ""
            r1.setDeviceName(r2)
        L444:
            boolean r1 = com.panasonic.jp.lumixlab.util.C1367b.g()
            if (r1 == 0) goto L471
            java.lang.Class<com.panasonic.jp.lumixlab.util.G0> r1 = com.panasonic.jp.lumixlab.util.G0.class
            monitor-enter(r1)
            monitor-exit(r1)
            java.util.HashMap r1 = new java.util.HashMap
            r1.<init>()
            java.lang.String r2 = "ActionName"
            java.lang.String r3 = "FirmwareTransferEnd"
            r1.put(r2, r3)
            java.lang.String r2 = "ァームウェア転送完了画面"
            com.panasonic.jp.lumixlab.util.C1367b.j(r2, r1)
            goto L471
        L460:
            r0.f17651o0 = r7
            r1 = 2132017679(0x7f14020f, float:1.9673643E38)
            java.lang.String r10 = r0.getString(r1)
            java.lang.Object[] r1 = new java.lang.Object[]{r11, r13}
            java.lang.String r14 = java.lang.String.format(r3, r1)
        L471:
            R1.a r1 = r0.f30774x
            D5.E1 r1 = (D5.E1) r1
            android.widget.TextView r1 = r1.f2977j
            r1.setText(r10)
            R1.a r0 = r0.f30774x
            D5.E1 r0 = (D5.E1) r0
            D5.r2 r0 = r0.f2970c
            android.widget.TextView r0 = r0.f4404b
            r0.setText(r14)
            return
    }
}
