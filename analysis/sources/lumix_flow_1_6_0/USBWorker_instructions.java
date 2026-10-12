package p038q0;

/* JADX INFO: loaded from: classes4.dex */
public final /* synthetic */ class X implements java.lang.Runnable {

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public final /* synthetic */ int f6819a;

    /* JADX INFO: renamed from: b, reason: collision with root package name */
    public final /* synthetic */ p038q0.a0 f6820b;

    public /* synthetic */ X(p038q0.a0 r1, int r2) {
            r0 = this;
            r0.f6819a = r2
            r0.f6820b = r1
            r0.<init>()
            return
    }

    private final void a() {
            r13 = this;
            q0.a0 r13 = r13.f6820b
            x0.f r0 = r13.e
            if (r0 != 0) goto L8
            goto L4b9
        L8:
            java.util.ArrayList r0 = r13.f6827i
            r0.clear()
            java.util.ArrayList r0 = r13.f6828j
            r0.clear()
            java.util.ArrayList r0 = r13.f6829k
            r0.clear()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.m r0 = r0.f3823g
            com.panasonic.jp.flow.app.FlowApp r1 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.k r1 = r1.f3826j
            com.panasonic.jp.flow.app.FlowApp r2 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.l r2 = r2.f3827k
            r3 = 4
            r4 = 0
            x0.f r5 = r13.e     // Catch: java.lang.Throwable -> L75
            w1.a r6 = new w1.a     // Catch: java.lang.Throwable -> L75
            r6.<init>()     // Catch: java.lang.Throwable -> L75
            r6.a(r3)     // Catch: java.lang.Throwable -> L75
            w1.c r7 = p054w1.c.Command     // Catch: java.lang.Throwable -> L75
            r6.j(r7)     // Catch: java.lang.Throwable -> L75
            s1.V r7 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L75
            r6.i(r7)     // Catch: java.lang.Throwable -> L75
            s1.D r7 = s1.D.Frame1AspectRatioSetting     // Catch: java.lang.Throwable -> L75
            int r7 = r7.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L75
            r6.f(r7)     // Catch: java.lang.Throwable -> L75
            z0.a r7 = new z0.a     // Catch: java.lang.Throwable -> L75
            r8 = 15
            r7.<init>(r8)     // Catch: java.lang.Throwable -> L75
            java.lang.Object r8 = r7.f7780b     // Catch: java.lang.Throwable -> L75
            w1.a r8 = (p054w1.a) r8     // Catch: java.lang.Throwable -> L75
            if (r8 != 0) goto L52
            r7.f7780b = r6     // Catch: java.lang.Throwable -> L75
            goto L54
        L52:
            r7.c = r6     // Catch: java.lang.Throwable -> L75
        L54:
            r1.e r6 = r7.d()     // Catch: java.lang.Throwable -> L75
            r1.d r4 = r5.c(r6)     // Catch: java.lang.Throwable -> L75
            v1.d r5 = X1.k.F(r4)     // Catch: java.lang.Throwable -> L75
            if (r5 == 0) goto L71
            java.lang.Object r5 = r5.d     // Catch: java.lang.Throwable -> L75
            v1.B0 r5 = (p051v1.B0) r5     // Catch: java.lang.Throwable -> L75
            if (r5 != 0) goto L6c
            r1.getClass()     // Catch: java.lang.Throwable -> L75
            goto L71
        L6c:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r6 = r1.d     // Catch: java.lang.Throwable -> L75
            r6.setFrame1AspectRatioSetting(r5)     // Catch: java.lang.Throwable -> L75
        L71:
            r4.a()
            goto L7c
        L75:
            r5 = move-exception
            r5.printStackTrace()     // Catch: java.lang.Throwable -> L507
            if (r4 == 0) goto L7c
            goto L71
        L7c:
            x0.f r5 = r13.e
            s1.D r6 = s1.D.LUTViewAssistSelectionSettingVLog
            long r7 = r6.getRawUpper()
            kotlin.jvm.internal.G r5 = r5.b(r7)
            r7 = 0
            r8 = 0
            if (r5 == 0) goto Lc4
            long r10 = r6.getRawUpper()
            y0.a r5 = r5.c(r10)
            if (r5 == 0) goto Lc4
            long r10 = r5.f7565b
            int r6 = (r10 > r8 ? 1 : (r10 == r8 ? 0 : -1))
            if (r6 <= 0) goto Lc4
            y0.e r5 = r5.a(r7)
            int r6 = r5.c
            if (r6 <= 0) goto Lc4
            monitor-enter(r13)
            short[] r5 = r5.e     // Catch: java.lang.Throwable -> Lba
            int r6 = r5.length     // Catch: java.lang.Throwable -> Lba
            r10 = r7
        Laa:
            if (r10 >= r6) goto Lbc
            short r11 = r5[r10]     // Catch: java.lang.Throwable -> Lba
            java.util.ArrayList r12 = r13.f6828j     // Catch: java.lang.Throwable -> Lba
            java.lang.Integer r11 = java.lang.Integer.valueOf(r11)     // Catch: java.lang.Throwable -> Lba
            r12.add(r11)     // Catch: java.lang.Throwable -> Lba
            int r10 = r10 + 1
            goto Laa
        Lba:
            r0 = move-exception
            goto Lc2
        Lbc:
            java.util.ArrayList r5 = r13.f6828j     // Catch: java.lang.Throwable -> Lba
            r2.d = r5     // Catch: java.lang.Throwable -> Lba
            monitor-exit(r13)     // Catch: java.lang.Throwable -> Lba
            goto Lc4
        Lc2:
            monitor-exit(r13)     // Catch: java.lang.Throwable -> Lba
            throw r0
        Lc4:
            r5 = 65535(0xffff, float:9.1834E-41)
            x0.f r6 = r13.e     // Catch: java.lang.Throwable -> L10d
            w1.a r10 = new w1.a     // Catch: java.lang.Throwable -> L10d
            r10.<init>()     // Catch: java.lang.Throwable -> L10d
            r10.a(r3)     // Catch: java.lang.Throwable -> L10d
            w1.c r11 = p054w1.c.Command     // Catch: java.lang.Throwable -> L10d
            r10.j(r11)     // Catch: java.lang.Throwable -> L10d
            s1.V r11 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L10d
            r10.i(r11)     // Catch: java.lang.Throwable -> L10d
            s1.D r11 = s1.D.LUTViewAssistSelectionSettingVLog     // Catch: java.lang.Throwable -> L10d
            int r11 = r11.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L10d
            r10.f(r11)     // Catch: java.lang.Throwable -> L10d
            z0.a r11 = new z0.a     // Catch: java.lang.Throwable -> L10d
            r12 = 15
            r11.<init>(r12)     // Catch: java.lang.Throwable -> L10d
            java.lang.Object r12 = r11.f7780b     // Catch: java.lang.Throwable -> L10d
            w1.a r12 = (p054w1.a) r12     // Catch: java.lang.Throwable -> L10d
            if (r12 != 0) goto Lf4
            r11.f7780b = r10     // Catch: java.lang.Throwable -> L10d
            goto Lf6
        Lf4:
            r11.c = r10     // Catch: java.lang.Throwable -> L10d
        Lf6:
            r1.e r10 = r11.d()     // Catch: java.lang.Throwable -> L10d
            r1.d r4 = r6.c(r10)     // Catch: java.lang.Throwable -> L10d
            v1.q1 r6 = X1.k.U(r4)     // Catch: java.lang.Throwable -> L10d
            if (r6 == 0) goto L109
            short r6 = r6.d     // Catch: java.lang.Throwable -> L10d
            r6 = r6 & r5
            r2.f7621a = r6     // Catch: java.lang.Throwable -> L10d
        L109:
            r4.a()
            goto L114
        L10d:
            r6 = move-exception
            r6.printStackTrace()     // Catch: java.lang.Throwable -> L500
            if (r4 == 0) goto L114
            goto L109
        L114:
            x0.f r6 = r13.e
            s1.D r10 = s1.D.LUTViewAssistSelectionSettingARRILogC3
            long r11 = r10.getRawUpper()
            kotlin.jvm.internal.G r6 = r6.b(r11)
            if (r6 == 0) goto L159
            long r10 = r10.getRawUpper()
            y0.a r6 = r6.c(r10)
            if (r6 == 0) goto L159
            long r10 = r6.f7565b
            int r8 = (r10 > r8 ? 1 : (r10 == r8 ? 0 : -1))
            if (r8 <= 0) goto L159
            y0.e r6 = r6.a(r7)
            int r8 = r6.c
            if (r8 <= 0) goto L159
            monitor-enter(r13)
            short[] r6 = r6.e     // Catch: java.lang.Throwable -> L14f
            int r8 = r6.length     // Catch: java.lang.Throwable -> L14f
            r9 = r7
        L13f:
            if (r9 >= r8) goto L151
            short r10 = r6[r9]     // Catch: java.lang.Throwable -> L14f
            java.util.ArrayList r11 = r13.f6829k     // Catch: java.lang.Throwable -> L14f
            java.lang.Integer r10 = java.lang.Integer.valueOf(r10)     // Catch: java.lang.Throwable -> L14f
            r11.add(r10)     // Catch: java.lang.Throwable -> L14f
            int r9 = r9 + 1
            goto L13f
        L14f:
            r0 = move-exception
            goto L157
        L151:
            java.util.ArrayList r6 = r13.f6829k     // Catch: java.lang.Throwable -> L14f
            r2.e = r6     // Catch: java.lang.Throwable -> L14f
            monitor-exit(r13)     // Catch: java.lang.Throwable -> L14f
            goto L159
        L157:
            monitor-exit(r13)     // Catch: java.lang.Throwable -> L14f
            throw r0
        L159:
            x0.f r6 = r13.e     // Catch: java.lang.Throwable -> L19f
            w1.a r8 = new w1.a     // Catch: java.lang.Throwable -> L19f
            r8.<init>()     // Catch: java.lang.Throwable -> L19f
            r8.a(r3)     // Catch: java.lang.Throwable -> L19f
            w1.c r9 = p054w1.c.Command     // Catch: java.lang.Throwable -> L19f
            r8.j(r9)     // Catch: java.lang.Throwable -> L19f
            s1.V r9 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L19f
            r8.i(r9)     // Catch: java.lang.Throwable -> L19f
            s1.D r9 = s1.D.LUTViewAssistSelectionSettingARRILogC3     // Catch: java.lang.Throwable -> L19f
            int r9 = r9.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L19f
            r8.f(r9)     // Catch: java.lang.Throwable -> L19f
            z0.a r9 = new z0.a     // Catch: java.lang.Throwable -> L19f
            r10 = 15
            r9.<init>(r10)     // Catch: java.lang.Throwable -> L19f
            java.lang.Object r10 = r9.f7780b     // Catch: java.lang.Throwable -> L19f
            w1.a r10 = (p054w1.a) r10     // Catch: java.lang.Throwable -> L19f
            if (r10 != 0) goto L186
            r9.f7780b = r8     // Catch: java.lang.Throwable -> L19f
            goto L188
        L186:
            r9.c = r8     // Catch: java.lang.Throwable -> L19f
        L188:
            r1.e r8 = r9.d()     // Catch: java.lang.Throwable -> L19f
            r1.d r4 = r6.c(r8)     // Catch: java.lang.Throwable -> L19f
            v1.q1 r6 = X1.k.T(r4)     // Catch: java.lang.Throwable -> L19f
            if (r6 == 0) goto L19b
            short r6 = r6.d     // Catch: java.lang.Throwable -> L19f
            r5 = r5 & r6
            r2.f7622b = r5     // Catch: java.lang.Throwable -> L19f
        L19b:
            r4.a()
            goto L1a6
        L19f:
            r2 = move-exception
            r2.printStackTrace()     // Catch: java.lang.Throwable -> L4f9
            if (r4 == 0) goto L1a6
            goto L19b
        L1a6:
            x0.f r2 = r13.e     // Catch: java.lang.Throwable -> L1f6
            w1.a r5 = new w1.a     // Catch: java.lang.Throwable -> L1f6
            r5.<init>()     // Catch: java.lang.Throwable -> L1f6
            r5.a(r3)     // Catch: java.lang.Throwable -> L1f6
            w1.c r6 = p054w1.c.Command     // Catch: java.lang.Throwable -> L1f6
            r5.j(r6)     // Catch: java.lang.Throwable -> L1f6
            s1.V r6 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L1f6
            r5.i(r6)     // Catch: java.lang.Throwable -> L1f6
            s1.D r6 = s1.D.Frame2AspectRatioSetting     // Catch: java.lang.Throwable -> L1f6
            int r6 = r6.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L1f6
            r5.f(r6)     // Catch: java.lang.Throwable -> L1f6
            z0.a r6 = new z0.a     // Catch: java.lang.Throwable -> L1f6
            r8 = 15
            r6.<init>(r8)     // Catch: java.lang.Throwable -> L1f6
            java.lang.Object r8 = r6.f7780b     // Catch: java.lang.Throwable -> L1f6
            w1.a r8 = (p054w1.a) r8     // Catch: java.lang.Throwable -> L1f6
            if (r8 != 0) goto L1d3
            r6.f7780b = r5     // Catch: java.lang.Throwable -> L1f6
            goto L1d5
        L1d3:
            r6.c = r5     // Catch: java.lang.Throwable -> L1f6
        L1d5:
            r1.e r5 = r6.d()     // Catch: java.lang.Throwable -> L1f6
            r1.d r4 = r2.c(r5)     // Catch: java.lang.Throwable -> L1f6
            v1.W0 r2 = X1.k.H(r4)     // Catch: java.lang.Throwable -> L1f6
            if (r2 == 0) goto L1f2
            java.lang.Object r2 = r2.d     // Catch: java.lang.Throwable -> L1f6
            v1.B0 r2 = (p051v1.B0) r2     // Catch: java.lang.Throwable -> L1f6
            if (r2 != 0) goto L1ed
            r1.getClass()     // Catch: java.lang.Throwable -> L1f6
            goto L1f2
        L1ed:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r5 = r1.d     // Catch: java.lang.Throwable -> L1f6
            r5.setFrame2AspectRatioSetting(r2)     // Catch: java.lang.Throwable -> L1f6
        L1f2:
            r4.a()
            goto L1fd
        L1f6:
            r2 = move-exception
            r2.printStackTrace()     // Catch: java.lang.Throwable -> L4f2
            if (r4 == 0) goto L1fd
            goto L1f2
        L1fd:
            x0.f r2 = r13.e     // Catch: java.lang.Throwable -> L24d
            w1.a r5 = new w1.a     // Catch: java.lang.Throwable -> L24d
            r5.<init>()     // Catch: java.lang.Throwable -> L24d
            r5.a(r3)     // Catch: java.lang.Throwable -> L24d
            w1.c r6 = p054w1.c.Command     // Catch: java.lang.Throwable -> L24d
            r5.j(r6)     // Catch: java.lang.Throwable -> L24d
            s1.V r6 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L24d
            r5.i(r6)     // Catch: java.lang.Throwable -> L24d
            s1.D r6 = s1.D.Frame3AspectRatioSetting     // Catch: java.lang.Throwable -> L24d
            int r6 = r6.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L24d
            r5.f(r6)     // Catch: java.lang.Throwable -> L24d
            z0.a r6 = new z0.a     // Catch: java.lang.Throwable -> L24d
            r8 = 15
            r6.<init>(r8)     // Catch: java.lang.Throwable -> L24d
            java.lang.Object r8 = r6.f7780b     // Catch: java.lang.Throwable -> L24d
            w1.a r8 = (p054w1.a) r8     // Catch: java.lang.Throwable -> L24d
            if (r8 != 0) goto L22a
            r6.f7780b = r5     // Catch: java.lang.Throwable -> L24d
            goto L22c
        L22a:
            r6.c = r5     // Catch: java.lang.Throwable -> L24d
        L22c:
            r1.e r5 = r6.d()     // Catch: java.lang.Throwable -> L24d
            r1.d r4 = r2.c(r5)     // Catch: java.lang.Throwable -> L24d
            v1.W0 r2 = X1.k.J(r4)     // Catch: java.lang.Throwable -> L24d
            if (r2 == 0) goto L249
            java.lang.Object r2 = r2.d     // Catch: java.lang.Throwable -> L24d
            v1.B0 r2 = (p051v1.B0) r2     // Catch: java.lang.Throwable -> L24d
            if (r2 != 0) goto L244
            r1.getClass()     // Catch: java.lang.Throwable -> L24d
            goto L249
        L244:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r5 = r1.d     // Catch: java.lang.Throwable -> L24d
            r5.setFrame3AspectRatioSetting(r2)     // Catch: java.lang.Throwable -> L24d
        L249:
            r4.a()
            goto L254
        L24d:
            r2 = move-exception
            r2.printStackTrace()     // Catch: java.lang.Throwable -> L4eb
            if (r4 == 0) goto L254
            goto L249
        L254:
            x0.f r2 = r13.e     // Catch: java.lang.Throwable -> L29a
            w1.a r5 = new w1.a     // Catch: java.lang.Throwable -> L29a
            r5.<init>()     // Catch: java.lang.Throwable -> L29a
            r5.a(r3)     // Catch: java.lang.Throwable -> L29a
            w1.c r6 = p054w1.c.Command     // Catch: java.lang.Throwable -> L29a
            r5.j(r6)     // Catch: java.lang.Throwable -> L29a
            s1.V r6 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L29a
            r5.i(r6)     // Catch: java.lang.Throwable -> L29a
            s1.D r6 = s1.D.Frame1ColorSetting     // Catch: java.lang.Throwable -> L29a
            int r6 = r6.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L29a
            r5.f(r6)     // Catch: java.lang.Throwable -> L29a
            z0.a r6 = new z0.a     // Catch: java.lang.Throwable -> L29a
            r8 = 15
            r6.<init>(r8)     // Catch: java.lang.Throwable -> L29a
            r6.k(r5)     // Catch: java.lang.Throwable -> L29a
            r1.e r5 = r6.d()     // Catch: java.lang.Throwable -> L29a
            r1.d r4 = r2.c(r5)     // Catch: java.lang.Throwable -> L29a
            v1.I r2 = X1.k.G(r4)     // Catch: java.lang.Throwable -> L29a
            if (r2 == 0) goto L296
            v1.x0 r2 = r2.d     // Catch: java.lang.Throwable -> L29a
            if (r2 != 0) goto L291
            r1.getClass()     // Catch: java.lang.Throwable -> L29a
            goto L296
        L291:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r5 = r1.d     // Catch: java.lang.Throwable -> L29a
            r5.setFrame1ColorSetting(r2)     // Catch: java.lang.Throwable -> L29a
        L296:
            r4.a()
            goto L2a1
        L29a:
            r2 = move-exception
            r2.printStackTrace()     // Catch: java.lang.Throwable -> L4e4
            if (r4 == 0) goto L2a1
            goto L296
        L2a1:
            x0.f r2 = r13.e     // Catch: java.lang.Throwable -> L2e7
            w1.a r5 = new w1.a     // Catch: java.lang.Throwable -> L2e7
            r5.<init>()     // Catch: java.lang.Throwable -> L2e7
            r5.a(r3)     // Catch: java.lang.Throwable -> L2e7
            w1.c r6 = p054w1.c.Command     // Catch: java.lang.Throwable -> L2e7
            r5.j(r6)     // Catch: java.lang.Throwable -> L2e7
            s1.V r6 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L2e7
            r5.i(r6)     // Catch: java.lang.Throwable -> L2e7
            s1.D r6 = s1.D.Frame2ColorSetting     // Catch: java.lang.Throwable -> L2e7
            int r6 = r6.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L2e7
            r5.f(r6)     // Catch: java.lang.Throwable -> L2e7
            z0.a r6 = new z0.a     // Catch: java.lang.Throwable -> L2e7
            r8 = 15
            r6.<init>(r8)     // Catch: java.lang.Throwable -> L2e7
            r6.k(r5)     // Catch: java.lang.Throwable -> L2e7
            r1.e r5 = r6.d()     // Catch: java.lang.Throwable -> L2e7
            r1.d r4 = r2.c(r5)     // Catch: java.lang.Throwable -> L2e7
            v1.X0 r2 = X1.k.I(r4)     // Catch: java.lang.Throwable -> L2e7
            if (r2 == 0) goto L2e3
            v1.x0 r2 = r2.d     // Catch: java.lang.Throwable -> L2e7
            if (r2 != 0) goto L2de
            r1.getClass()     // Catch: java.lang.Throwable -> L2e7
            goto L2e3
        L2de:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r5 = r1.d     // Catch: java.lang.Throwable -> L2e7
            r5.setFrame2ColorSetting(r2)     // Catch: java.lang.Throwable -> L2e7
        L2e3:
            r4.a()
            goto L2ee
        L2e7:
            r2 = move-exception
            r2.printStackTrace()     // Catch: java.lang.Throwable -> L4dd
            if (r4 == 0) goto L2ee
            goto L2e3
        L2ee:
            x0.f r2 = r13.e     // Catch: java.lang.Throwable -> L334
            w1.a r5 = new w1.a     // Catch: java.lang.Throwable -> L334
            r5.<init>()     // Catch: java.lang.Throwable -> L334
            r5.a(r3)     // Catch: java.lang.Throwable -> L334
            w1.c r6 = p054w1.c.Command     // Catch: java.lang.Throwable -> L334
            r5.j(r6)     // Catch: java.lang.Throwable -> L334
            s1.V r6 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L334
            r5.i(r6)     // Catch: java.lang.Throwable -> L334
            s1.D r6 = s1.D.Frame3ColorSetting     // Catch: java.lang.Throwable -> L334
            int r6 = r6.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L334
            r5.f(r6)     // Catch: java.lang.Throwable -> L334
            z0.a r6 = new z0.a     // Catch: java.lang.Throwable -> L334
            r8 = 15
            r6.<init>(r8)     // Catch: java.lang.Throwable -> L334
            r6.k(r5)     // Catch: java.lang.Throwable -> L334
            r1.e r5 = r6.d()     // Catch: java.lang.Throwable -> L334
            r1.d r4 = r2.c(r5)     // Catch: java.lang.Throwable -> L334
            v1.X0 r2 = X1.k.K(r4)     // Catch: java.lang.Throwable -> L334
            if (r2 == 0) goto L330
            v1.x0 r2 = r2.d     // Catch: java.lang.Throwable -> L334
            if (r2 != 0) goto L32b
            r1.getClass()     // Catch: java.lang.Throwable -> L334
            goto L330
        L32b:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r5 = r1.d     // Catch: java.lang.Throwable -> L334
            r5.setFrame3ColorSetting(r2)     // Catch: java.lang.Throwable -> L334
        L330:
            r4.a()
            goto L33b
        L334:
            r2 = move-exception
            r2.printStackTrace()     // Catch: java.lang.Throwable -> L4d6
            if (r4 == 0) goto L33b
            goto L330
        L33b:
            r2 = 1
            x0.f r5 = r13.e     // Catch: java.lang.Throwable -> L386
            w1.a r6 = new w1.a     // Catch: java.lang.Throwable -> L386
            r6.<init>()     // Catch: java.lang.Throwable -> L386
            r6.a(r3)     // Catch: java.lang.Throwable -> L386
            w1.c r8 = p054w1.c.Command     // Catch: java.lang.Throwable -> L386
            r6.j(r8)     // Catch: java.lang.Throwable -> L386
            s1.V r8 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L386
            r6.i(r8)     // Catch: java.lang.Throwable -> L386
            s1.D r8 = s1.D.LUTViewAssist     // Catch: java.lang.Throwable -> L386
            int r8 = r8.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L386
            r6.f(r8)     // Catch: java.lang.Throwable -> L386
            z0.a r8 = new z0.a     // Catch: java.lang.Throwable -> L386
            r9 = 15
            r8.<init>(r9)     // Catch: java.lang.Throwable -> L386
            r8.k(r6)     // Catch: java.lang.Throwable -> L386
            r1.e r6 = r8.d()     // Catch: java.lang.Throwable -> L386
            r1.d r4 = r5.c(r6)     // Catch: java.lang.Throwable -> L386
            v1.a r5 = X1.k.Q(r4)     // Catch: java.lang.Throwable -> L386
            if (r5 == 0) goto L382
            u1.d r5 = r5.d     // Catch: java.lang.Throwable -> L386
            r0.getClass()     // Catch: java.lang.Throwable -> L386
            if (r5 != 0) goto L379
            goto L382
        L379:
            u1.d r6 = p048u1.d.ON     // Catch: java.lang.Throwable -> L386
            if (r5 != r6) goto L37f
            r5 = r2
            goto L380
        L37f:
            r5 = r7
        L380:
            r0.e = r5     // Catch: java.lang.Throwable -> L386
        L382:
            r4.a()
            goto L38d
        L386:
            r5 = move-exception
            r5.printStackTrace()     // Catch: java.lang.Throwable -> L4cf
            if (r4 == 0) goto L38d
            goto L382
        L38d:
            x0.f r5 = r13.e     // Catch: java.lang.Throwable -> L3d5
            w1.a r6 = new w1.a     // Catch: java.lang.Throwable -> L3d5
            r6.<init>()     // Catch: java.lang.Throwable -> L3d5
            r6.a(r3)     // Catch: java.lang.Throwable -> L3d5
            w1.c r8 = p054w1.c.Command     // Catch: java.lang.Throwable -> L3d5
            r6.j(r8)     // Catch: java.lang.Throwable -> L3d5
            s1.V r8 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L3d5
            r6.i(r8)     // Catch: java.lang.Throwable -> L3d5
            s1.D r8 = s1.D.FrameDisplaySetting     // Catch: java.lang.Throwable -> L3d5
            int r8 = r8.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L3d5
            r6.f(r8)     // Catch: java.lang.Throwable -> L3d5
            z0.a r8 = new z0.a     // Catch: java.lang.Throwable -> L3d5
            r9 = 15
            r8.<init>(r9)     // Catch: java.lang.Throwable -> L3d5
            r8.k(r6)     // Catch: java.lang.Throwable -> L3d5
            r1.e r6 = r8.d()     // Catch: java.lang.Throwable -> L3d5
            r1.d r4 = r5.c(r6)     // Catch: java.lang.Throwable -> L3d5
            v1.a r5 = X1.k.O(r4)     // Catch: java.lang.Throwable -> L3d5
            if (r5 == 0) goto L3d1
            u1.d r5 = r5.d     // Catch: java.lang.Throwable -> L3d5
            r0.getClass()     // Catch: java.lang.Throwable -> L3d5
            if (r5 != 0) goto L3ca
            goto L3d1
        L3ca:
            u1.d r6 = p048u1.d.ON     // Catch: java.lang.Throwable -> L3d5
            if (r5 != r6) goto L3cf
            r7 = r2
        L3cf:
            r0.f = r7     // Catch: java.lang.Throwable -> L3d5
        L3d1:
            r4.a()
            goto L3dc
        L3d5:
            r0 = move-exception
            r0.printStackTrace()     // Catch: java.lang.Throwable -> L4c8
            if (r4 == 0) goto L3dc
            goto L3d1
        L3dc:
            x0.f r0 = r13.e     // Catch: java.lang.Throwable -> L42f
            w1.a r2 = new w1.a     // Catch: java.lang.Throwable -> L42f
            r2.<init>()     // Catch: java.lang.Throwable -> L42f
            r2.a(r3)     // Catch: java.lang.Throwable -> L42f
            w1.c r5 = p054w1.c.Command     // Catch: java.lang.Throwable -> L42f
            r2.j(r5)     // Catch: java.lang.Throwable -> L42f
            s1.V r5 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L42f
            r2.i(r5)     // Catch: java.lang.Throwable -> L42f
            s1.D r5 = s1.D.FrameCoordinateInformation     // Catch: java.lang.Throwable -> L42f
            int r5 = r5.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L42f
            r2.f(r5)     // Catch: java.lang.Throwable -> L42f
            z0.a r5 = new z0.a     // Catch: java.lang.Throwable -> L42f
            r6 = 15
            r5.<init>(r6)     // Catch: java.lang.Throwable -> L42f
            r5.k(r2)     // Catch: java.lang.Throwable -> L42f
            r1.e r2 = r5.d()     // Catch: java.lang.Throwable -> L42f
            r1.d r4 = r0.c(r2)     // Catch: java.lang.Throwable -> L42f
            v1.O r0 = X1.k.L(r4)     // Catch: java.lang.Throwable -> L42f
            if (r0 == 0) goto L42b
            java.util.ArrayList r0 = r0.d     // Catch: java.lang.Throwable -> L42f
            if (r0 != 0) goto L419
            r1.getClass()     // Catch: java.lang.Throwable -> L42f
            goto L42b
        L419:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r2 = r1.d     // Catch: java.lang.Throwable -> L42f
            java.util.List r2 = r2.getListData()     // Catch: java.lang.Throwable -> L42f
            monitor-enter(r2)     // Catch: java.lang.Throwable -> L42f
            r2.clear()     // Catch: java.lang.Throwable -> L428
            r2.addAll(r0)     // Catch: java.lang.Throwable -> L428
            monitor-exit(r2)     // Catch: java.lang.Throwable -> L428
            goto L42b
        L428:
            r0 = move-exception
            monitor-exit(r2)     // Catch: java.lang.Throwable -> L428
            throw r0     // Catch: java.lang.Throwable -> L42f
        L42b:
            r4.a()
            goto L436
        L42f:
            r0 = move-exception
            r0.printStackTrace()     // Catch: java.lang.Throwable -> L4c1
            if (r4 == 0) goto L436
            goto L42b
        L436:
            x0.f r0 = r13.e     // Catch: java.lang.Throwable -> L47e
            w1.a r2 = new w1.a     // Catch: java.lang.Throwable -> L47e
            r2.<init>()     // Catch: java.lang.Throwable -> L47e
            r2.a(r3)     // Catch: java.lang.Throwable -> L47e
            w1.c r3 = p054w1.c.Command     // Catch: java.lang.Throwable -> L47e
            r2.j(r3)     // Catch: java.lang.Throwable -> L47e
            s1.V r3 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L47e
            r2.i(r3)     // Catch: java.lang.Throwable -> L47e
            s1.D r3 = s1.D.FrameMaskSetting     // Catch: java.lang.Throwable -> L47e
            int r3 = r3.m4670getRawpVg5ArA()     // Catch: java.lang.Throwable -> L47e
            r2.f(r3)     // Catch: java.lang.Throwable -> L47e
            z0.a r3 = new z0.a     // Catch: java.lang.Throwable -> L47e
            r5 = 15
            r3.<init>(r5)     // Catch: java.lang.Throwable -> L47e
            r3.k(r2)     // Catch: java.lang.Throwable -> L47e
            r1.e r2 = r3.d()     // Catch: java.lang.Throwable -> L47e
            r1.d r4 = r0.c(r2)     // Catch: java.lang.Throwable -> L47e
            v1.d r0 = X1.k.A(r4)     // Catch: java.lang.Throwable -> L47e
            if (r0 == 0) goto L47a
            java.lang.Object r0 = r0.d     // Catch: java.lang.Throwable -> L47e
            v1.a1 r0 = (p051v1.EnumC1011a1) r0     // Catch: java.lang.Throwable -> L47e
            if (r0 != 0) goto L475
            r1.getClass()     // Catch: java.lang.Throwable -> L47e
            goto L47a
        L475:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r2 = r1.d     // Catch: java.lang.Throwable -> L47e
            r2.setFrameMaskSettingsValue(r0)     // Catch: java.lang.Throwable -> L47e
        L47a:
            r4.a()
            goto L485
        L47e:
            r0 = move-exception
            r0.printStackTrace()     // Catch: java.lang.Throwable -> L4ba
            if (r4 == 0) goto L485
            goto L47a
        L485:
            java.util.ArrayList r0 = r13.f6827i
            v1.a1 r2 = p051v1.EnumC1011a1.F100
            r0.add(r2)
            java.util.ArrayList r0 = r13.f6827i
            v1.a1 r2 = p051v1.EnumC1011a1.F75
            r0.add(r2)
            java.util.ArrayList r0 = r13.f6827i
            v1.a1 r2 = p051v1.EnumC1011a1.F50
            r0.add(r2)
            java.util.ArrayList r0 = r13.f6827i
            v1.a1 r2 = p051v1.EnumC1011a1.F25
            r0.add(r2)
            java.util.ArrayList r0 = r13.f6827i
            v1.a1 r2 = p051v1.EnumC1011a1.OFF
            r0.add(r2)
            java.util.ArrayList r13 = r13.f6827i
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r0 = r1.d
            r0.setFrameMaskSettingsValueList(r13)
            java.lang.String r13 = "onPhotographyAidsChanged"
            p038q0.a0.i(r13)
            java.lang.String r13 = "onFrameChanged"
            p038q0.a0.i(r13)
        L4b9:
            return
        L4ba:
            r13 = move-exception
            if (r4 == 0) goto L4c0
            r4.a()
        L4c0:
            throw r13
        L4c1:
            r13 = move-exception
            if (r4 == 0) goto L4c7
            r4.a()
        L4c7:
            throw r13
        L4c8:
            r13 = move-exception
            if (r4 == 0) goto L4ce
            r4.a()
        L4ce:
            throw r13
        L4cf:
            r13 = move-exception
            if (r4 == 0) goto L4d5
            r4.a()
        L4d5:
            throw r13
        L4d6:
            r13 = move-exception
            if (r4 == 0) goto L4dc
            r4.a()
        L4dc:
            throw r13
        L4dd:
            r13 = move-exception
            if (r4 == 0) goto L4e3
            r4.a()
        L4e3:
            throw r13
        L4e4:
            r13 = move-exception
            if (r4 == 0) goto L4ea
            r4.a()
        L4ea:
            throw r13
        L4eb:
            r13 = move-exception
            if (r4 == 0) goto L4f1
            r4.a()
        L4f1:
            throw r13
        L4f2:
            r13 = move-exception
            if (r4 == 0) goto L4f8
            r4.a()
        L4f8:
            throw r13
        L4f9:
            r13 = move-exception
            if (r4 == 0) goto L4ff
            r4.a()
        L4ff:
            throw r13
        L500:
            r13 = move-exception
            if (r4 == 0) goto L506
            r4.a()
        L506:
            throw r13
        L507:
            r13 = move-exception
            if (r4 == 0) goto L50d
            r4.a()
        L50d:
            throw r13
    }

    private final void b() {
            r9 = this;
            q0.a0 r9 = r9.f6820b
            x0.f r0 = r9.e
            r1 = 0
            if (r0 == 0) goto L25
            x0.a r0 = r0.f7544b
            if (r0 == 0) goto Le
            r0.a()
        Le:
            x0.f r0 = r9.e
            x0.e r2 = r0.c
            if (r2 == 0) goto L25
            com.panasonic.jp.flow.app.FlowApp r3 = com.panasonic.jp.flow.app.FlowApp.f3797R
            android.os.Handler r3 = r3.f3822b
            J0.G r4 = new J0.G
            r5 = 13
            r4.<init>(r5, r2, r1)
            r3.post(r4)
            r2 = 0
            r0.c = r2
        L25:
            r1.h r9 = r9.d
            if (r9 == 0) goto Le4
            android.hardware.usb.UsbDeviceConnection r0 = r9.f()
            com.panasonic.jp.flow.app.FlowApp r2 = com.panasonic.jp.flow.app.FlowApp.f3797R
            monitor-enter(r2)
            boolean r3 = r2.f3834r     // Catch: java.lang.Throwable -> Le1
            monitor-exit(r2)
            if (r3 == 0) goto Lda
            java.lang.String r2 = "sendXmlCancel end"
            java.lang.String r3 = "sendXmlCancel="
            java.lang.String r4 = "sendXmlCancel ret="
            java.io.PrintStream r5 = java.lang.System.out
            java.lang.String r6 = "sendXmlCancel begin"
            r5.println(r6)
            boolean r6 = r9.f7156p
            if (r6 != 0) goto L48
            goto Lda
        L48:
            r9.f7156p = r1
            s1.O r1 = s1.O.SendInterrupt     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            java.lang.String r6 = "status"
            kotlin.jvm.internal.p.f(r1, r6)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            w1.a r6 = new w1.a     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.<init>()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r7 = 4
            r6.a(r7)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            w1.c r7 = p054w1.c.Command     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.j(r7)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            s1.V r7 = s1.V.LuxEndOfSendData     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.i(r7)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            int r1 = r1.m4680getRawpVg5ArA()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.f(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            z0.a r1 = new z0.a     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r7 = 15
            r1.<init>(r7)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            java.lang.Object r7 = r1.f7780b     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            w1.a r7 = (p054w1.a) r7     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            if (r7 != 0) goto L7b
            r1.f7780b = r6     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            goto L7d
        L7b:
            r1.c = r6     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
        L7d:
            r1.e r1 = r1.d()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            byte[] r1 = r1.f7141b     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            kotlin.jvm.internal.p.c(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            android.hardware.usb.UsbEndpoint r6 = r9.f7149i     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            int r7 = r1.length     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r8 = 500(0x1f4, float:7.0E-43)
            int r1 = r0.bulkTransfer(r6, r1, r7, r8)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            java.lang.StringBuilder r6 = new java.lang.StringBuilder     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.<init>(r4)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.append(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            java.lang.String r1 = r6.toString()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r5.println(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            x1.d r1 = p057x1.d.f()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            int r4 = r9.f7151k     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            byte[] r1 = r1.e(r4)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            android.hardware.usb.UsbEndpoint r4 = r9.f7148h     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            int r6 = r1.length     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r0.bulkTransfer(r4, r1, r6, r8)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            s1.X r4 = p040r1.h.l(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            x1.d r6 = p057x1.d.f()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r6.h(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            java.lang.StringBuilder r1 = new java.lang.StringBuilder     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r1.<init>(r3)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r1.append(r4)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            java.lang.String r1 = r1.toString()     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r5.println(r1)     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            s1.W r1 = s1.X.Companion     // Catch: java.lang.Throwable -> Lce java.lang.Exception -> Ld5
            r5.println(r2)
            goto Lda
        Lce:
            r9 = move-exception
            java.io.PrintStream r0 = java.lang.System.out
            r0.println(r2)
            throw r9
        Ld5:
            java.io.PrintStream r1 = java.lang.System.out
            r1.println(r2)
        Lda:
            r9.a(r0)
            r9.b(r0)
            goto Le4
        Le1:
            r9 = move-exception
            monitor-exit(r2)     // Catch: java.lang.Throwable -> Le1
            throw r9
        Le4:
            return
    }

    private final void c() {
            r11 = this;
            q0.a0 r11 = r11.f6820b
            r11.getClass()
            r0 = 0
            x0.f r11 = r11.e     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            w1.a r1 = new w1.a     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r1.<init>()     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r2 = 4
            r1.a(r2)     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            w1.c r2 = p054w1.c.Command     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r1.j(r2)     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            s1.V r2 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r1.i(r2)     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            s1.f r2 = s1.EnumC0991f.GetAll     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            int r2 = r2.m4694getRawpVg5ArA()     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r1.f(r2)     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            z0.a r2 = new z0.a     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r3 = 15
            r2.<init>(r3)     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            java.lang.Object r3 = r2.f7780b     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            w1.a r3 = (p054w1.a) r3     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            if (r3 != 0) goto L34
            r2.f7780b = r1     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            goto L36
        L34:
            r2.c = r1     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
        L36:
            r1.e r1 = r2.d()     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            r1.d r11 = r11.c(r1)     // Catch: java.lang.Throwable -> L9c java.lang.Exception -> La1
            v1.y r1 = X1.k.i(r11)     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            if (r1 != 0) goto L49
        L44:
            r11.a()
            goto Lab
        L49:
            v1.z r2 = r1.f7481a     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            com.panasonic.jp.flow.app.FlowApp r3 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            y0.g r3 = r3.f3825i     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            v1.x r4 = r1.d     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            int[] r4 = r4.x()     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            com.panasonic.jp.flow.data.af.AFZoneData r5 = r3.f7576k     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r5.setAfZoneData(r4)     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            v1.A r4 = r1.e     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            short r5 = r4.c     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r6 = 65535(0xffff, float:9.1834E-41)
            r5 = r5 & r6
            short r4 = r4.d     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r4 = r4 & r6
            int[] r4 = new int[]{r5, r4}     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r3.W(r0, r0, r4)     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            short r0 = r2.c     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r5 = r0 & r6
            short r0 = r2.d     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r0 = r0 & r6
            short r4 = r2.e     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r7 = r4 & r6
            short r4 = r2.f     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r8 = r4 & r6
            u1.d r9 = r2.f7488g     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r4 = r3
            r6 = r0
            r4.R(r5, r6, r7, r8, r9)     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            v1.w r0 = r1.f7482b     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            java.lang.Object r0 = r0.e     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            v1.A1 r0 = (p051v1.A1) r0     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r3.f7574i = r0     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            v1.w r0 = r1.f7482b     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            java.lang.Object r0 = r0.d     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            v1.c0 r0 = (p051v1.EnumC1016c0) r0     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            r3.f7573h = r0     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            java.lang.String r0 = "onAFStatesChanged"
            p038q0.a0.i(r0)     // Catch: java.lang.Throwable -> L98 java.lang.Exception -> L9a
            goto L44
        L98:
            r0 = move-exception
            goto Lac
        L9a:
            r0 = move-exception
            goto La5
        L9c:
            r11 = move-exception
            r10 = r0
            r0 = r11
            r11 = r10
            goto Lac
        La1:
            r11 = move-exception
            r10 = r0
            r0 = r11
            r11 = r10
        La5:
            r0.printStackTrace()     // Catch: java.lang.Throwable -> L98
            if (r11 == 0) goto Lab
            goto L44
        Lab:
            return
        Lac:
            if (r11 == 0) goto Lb1
            r11.a()
        Lb1:
            throw r0
    }

    private final void d() {
            r3 = this;
            q0.a0 r3 = r3.f6820b
            s1.o r0 = s1.EnumC1000o.GetAll
            java.lang.String r1 = "tag"
            kotlin.jvm.internal.p.f(r0, r1)
            w1.a r1 = new w1.a
            r1.<init>()
            r2 = 4
            r1.a(r2)
            w1.c r2 = p054w1.c.Command
            r1.j(r2)
            s1.V r2 = s1.V.LuxGetPramInfo
            r1.i(r2)
            int r0 = r0.m4703getRawpVg5ArA()
            r1.f(r0)
            z0.a r0 = new z0.a
            r2 = 15
            r0.<init>(r2)
            java.lang.Object r2 = r0.f7780b
            w1.a r2 = (p054w1.a) r2
            if (r2 != 0) goto L33
            r0.f7780b = r1
            goto L35
        L33:
            r0.c = r1
        L35:
            r1.e r0 = r0.d()
            x0.f r3 = r3.e     // Catch: java.lang.Exception -> L56
            r1.d r3 = r3.c(r0)     // Catch: java.lang.Exception -> L56
            if (r3 == 0) goto L58
            v1.N0 r0 = X1.k.r(r3)     // Catch: java.lang.Exception -> L56
            if (r0 == 0) goto L58
            com.panasonic.jp.flow.app.FlowApp r1 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Exception -> L56
            y0.j r1 = r1.f     // Catch: java.lang.Exception -> L56
            com.panasonic.jp.flow.data.expose.FData r2 = r1.f7615a     // Catch: java.lang.Exception -> L56
            r2.updateExF(r0)     // Catch: java.lang.Exception -> L56
            com.panasonic.jp.flow.data.expose.SSData r1 = r1.c     // Catch: java.lang.Exception -> L56
            r1.updateExSS(r0)     // Catch: java.lang.Exception -> L56
            goto L58
        L56:
            r3 = move-exception
            goto L5c
        L58:
            r3.a()     // Catch: java.lang.Exception -> L56
            goto L5f
        L5c:
            r3.printStackTrace()
        L5f:
            E0.i r3 = E0.EnumC0343i.PHTOT_STYLE
            int r3 = r3.ordinal()
            java.lang.String r0 = "onCameraInfoSettingChanged"
            p038q0.a0.h(r3, r0)
            return
    }

    private final void e() {
            r6 = this;
            java.lang.String r0 = "NotifyCenter"
            java.lang.String r1 = "getErrorInfo response="
            q0.a0 r6 = r6.f6820b
            x0.f r6 = r6.e
            if (r6 != 0) goto Lc
            goto Lab
        Lc:
            w1.a r2 = new w1.a     // Catch: java.lang.Exception -> L4a
            r2.<init>()     // Catch: java.lang.Exception -> L4a
            r3 = 4
            r2.a(r3)     // Catch: java.lang.Exception -> L4a
            w1.c r3 = p054w1.c.Command     // Catch: java.lang.Exception -> L4a
            r2.j(r3)     // Catch: java.lang.Exception -> L4a
            s1.V r3 = s1.V.LuxGetPramInfo     // Catch: java.lang.Exception -> L4a
            r2.i(r3)     // Catch: java.lang.Exception -> L4a
            s1.n r3 = s1.EnumC0999n.ErrorInfo     // Catch: java.lang.Exception -> L4a
            int r3 = r3.m4702getRawpVg5ArA()     // Catch: java.lang.Exception -> L4a
            r2.f(r3)     // Catch: java.lang.Exception -> L4a
            z0.a r3 = new z0.a     // Catch: java.lang.Exception -> L4a
            r4 = 15
            r3.<init>(r4)     // Catch: java.lang.Exception -> L4a
            java.lang.Object r4 = r3.f7780b     // Catch: java.lang.Exception -> L4a
            w1.a r4 = (p054w1.a) r4     // Catch: java.lang.Exception -> L4a
            if (r4 != 0) goto L38
            r3.f7780b = r2     // Catch: java.lang.Exception -> L4a
            goto L3a
        L38:
            r3.c = r2     // Catch: java.lang.Exception -> L4a
        L3a:
            r1.e r2 = r3.d()     // Catch: java.lang.Exception -> L4a
            r1.d r6 = r6.c(r2)     // Catch: java.lang.Exception -> L4a
            if (r6 != 0) goto L4c
            if (r6 == 0) goto Lab
        L46:
            r6.a()     // Catch: java.lang.Exception -> L4a
            goto Lab
        L4a:
            r6 = move-exception
            goto La8
        L4c:
            java.lang.StringBuilder r2 = new java.lang.StringBuilder     // Catch: java.lang.Throwable -> L9c
            r2.<init>(r1)     // Catch: java.lang.Throwable -> L9c
            s1.X r1 = r6.f7139b     // Catch: java.lang.Throwable -> L9c
            r2.append(r1)     // Catch: java.lang.Throwable -> L9c
            java.lang.String r1 = r2.toString()     // Catch: java.lang.Throwable -> L9c
            com.panasonic.jp.flow.utils.Logger.d(r0, r1)     // Catch: java.lang.Throwable -> L9c
            v1.x r1 = X1.k.p(r6)     // Catch: java.lang.Throwable -> L9c
            java.lang.Object r1 = r1.c     // Catch: java.lang.Throwable -> L9c
            v1.n2[] r1 = (p051v1.n2[]) r1     // Catch: java.lang.Throwable -> L9c
            int r2 = r1.length     // Catch: java.lang.Throwable -> L9c
            r3 = 0
        L67:
            if (r3 >= r2) goto L7f
            r4 = r1[r3]     // Catch: java.lang.Throwable -> L9c
            int[] r5 = p051v1.C0.f7343a     // Catch: java.lang.Throwable -> L9c
            int r4 = r4.ordinal()     // Catch: java.lang.Throwable -> L9c
            r4 = r5[r4]     // Catch: java.lang.Throwable -> L9c
            r5 = 1
            if (r4 == r5) goto L80
            r5 = 2
            if (r4 == r5) goto L80
            r5 = 3
            if (r4 == r5) goto L80
            int r3 = r3 + 1
            goto L67
        L7f:
            r5 = -1
        L80:
            if (r5 <= 0) goto L9e
            java.lang.StringBuilder r1 = new java.lang.StringBuilder     // Catch: java.lang.Throwable -> L9c
            r1.<init>()     // Catch: java.lang.Throwable -> L9c
            java.lang.String r2 = "getErrorInfo Msg -> Card Full!  SDCardNo.="
            r1.append(r2)     // Catch: java.lang.Throwable -> L9c
            r1.append(r5)     // Catch: java.lang.Throwable -> L9c
            java.lang.String r1 = r1.toString()     // Catch: java.lang.Throwable -> L9c
            com.panasonic.jp.flow.utils.Logger.d(r0, r1)     // Catch: java.lang.Throwable -> L9c
            java.lang.String r0 = "onCameraErrorMsg"
            p038q0.a0.h(r5, r0)     // Catch: java.lang.Throwable -> L9c
            goto L46
        L9c:
            r0 = move-exception
            goto La4
        L9e:
            java.lang.String r1 = "getErrorInfo Msg -> other"
            com.panasonic.jp.flow.utils.Logger.d(r0, r1)     // Catch: java.lang.Throwable -> L9c
            goto L46
        La4:
            r6.a()     // Catch: java.lang.Exception -> L4a
            throw r0     // Catch: java.lang.Exception -> L4a
        La8:
            r6.printStackTrace()
        Lab:
            return
    }

    private final void f() {
            r1 = this;
            q0.a0 r1 = r1.f6820b
            r1.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.i r0 = r0.f3824h
            x0.f r1 = r1.e
            r0.q(r1)
            E0.i r1 = E0.EnumC0343i.BATTERY_STAUS
            int r1 = r1.ordinal()
            java.lang.String r0 = "onCameraInfoSettingChanged"
            p038q0.a0.h(r1, r0)
            return
    }

    private final void g() {
            r1 = this;
            q0.a0 r1 = r1.f6820b
            r1.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.i r0 = r0.f3824h
            x0.f r1 = r1.e
            r0.r(r1)
            E0.i r1 = E0.EnumC0343i.BATTERY_STAUS
            int r1 = r1.ordinal()
            java.lang.String r0 = "onCameraInfoSettingChanged"
            p038q0.a0.h(r1, r0)
            return
    }

    private final void h() {
            r1 = this;
            q0.a0 r1 = r1.f6820b
            r1.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.i r0 = r0.f3824h
            x0.f r1 = r1.e
            r0.t(r1)
            E0.i r1 = E0.EnumC0343i.PHTOT_STYLE
            int r1 = r1.ordinal()
            java.lang.String r0 = "onCameraInfoSettingChanged"
            p038q0.a0.h(r1, r0)
            return
    }

    private final void i() {
            r4 = this;
            q0.a0 r4 = r4.f6820b
            r4.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.i r0 = r0.f3824h
            x0.f r4 = r4.e
            java.lang.String r1 = r0.f7593a
            java.lang.String r2 = "requestFLowCameraHDMI"
            com.panasonic.jp.flow.utils.Logger.d(r1, r2)
            if (r4 != 0) goto L15
            goto L6b
        L15:
            w1.a r1 = new w1.a     // Catch: java.lang.Exception -> L53
            r1.<init>()     // Catch: java.lang.Exception -> L53
            r2 = 4
            r1.a(r2)     // Catch: java.lang.Exception -> L53
            w1.c r2 = p054w1.c.Command     // Catch: java.lang.Exception -> L53
            r1.j(r2)     // Catch: java.lang.Exception -> L53
            s1.V r2 = s1.V.LuxGetPramInfo     // Catch: java.lang.Exception -> L53
            r1.i(r2)     // Catch: java.lang.Exception -> L53
            s1.q r2 = s1.EnumC1002q.HDMI     // Catch: java.lang.Exception -> L53
            int r2 = r2.m4705getRawpVg5ArA()     // Catch: java.lang.Exception -> L53
            r1.f(r2)     // Catch: java.lang.Exception -> L53
            z0.a r2 = new z0.a     // Catch: java.lang.Exception -> L53
            r3 = 15
            r2.<init>(r3)     // Catch: java.lang.Exception -> L53
            java.lang.Object r3 = r2.f7780b     // Catch: java.lang.Exception -> L53
            w1.a r3 = (p054w1.a) r3     // Catch: java.lang.Exception -> L53
            if (r3 != 0) goto L41
            r2.f7780b = r1     // Catch: java.lang.Exception -> L53
            goto L43
        L41:
            r2.c = r1     // Catch: java.lang.Exception -> L53
        L43:
            r1.e r1 = r2.d()     // Catch: java.lang.Exception -> L53
            r1.d r4 = r4.c(r1)     // Catch: java.lang.Exception -> L53
            if (r4 != 0) goto L55
            if (r4 == 0) goto L6b
        L4f:
            r4.a()     // Catch: java.lang.Exception -> L53
            goto L6b
        L53:
            r4 = move-exception
            goto L68
        L55:
            v1.x r1 = X1.k.v(r4)     // Catch: java.lang.Throwable -> L63
            if (r1 != 0) goto L5c
            goto L4f
        L5c:
            java.lang.Object r1 = r1.c     // Catch: java.lang.Throwable -> L63
            u1.d r1 = (p048u1.d) r1     // Catch: java.lang.Throwable -> L63
            r0.f7590B = r1     // Catch: java.lang.Throwable -> L63
            goto L4f
        L63:
            r1 = move-exception
            r4.a()     // Catch: java.lang.Exception -> L53
            throw r1     // Catch: java.lang.Exception -> L53
        L68:
            r4.printStackTrace()
        L6b:
            java.lang.String r4 = "onFlowLumixHDMIConnecting"
            boolean r0 = r0.k()
            p038q0.a0.j(r4, r0)
            return
    }

    private final void j() {
            r10 = this;
            q0.a0 r10 = r10.f6820b
            x0.f r0 = r10.e
            if (r0 != 0) goto L8
            goto L1f4
        L8:
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.m r0 = r0.f3823g
            java.lang.String r1 = "getPhotographyAidsHistogramSettingInfo"
            java.lang.String r2 = "NotifyCenter"
            com.panasonic.jp.flow.utils.Logger.d(r2, r1)
            r1 = 1
            r3 = 0
            r4 = 4
            r5 = 0
            x0.f r6 = r10.e     // Catch: java.lang.Throwable -> L69
            w1.a r7 = new w1.a     // Catch: java.lang.Throwable -> L69
            r7.<init>()     // Catch: java.lang.Throwable -> L69
            r7.a(r4)     // Catch: java.lang.Throwable -> L69
            w1.c r8 = p054w1.c.Command     // Catch: java.lang.Throwable -> L69
            r7.j(r8)     // Catch: java.lang.Throwable -> L69
            s1.V r8 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L69
            r7.i(r8)     // Catch: java.lang.Throwable -> L69
            s1.E r8 = s1.E.Histogram     // Catch: java.lang.Throwable -> L69
            int r8 = r8.m4671getRawpVg5ArA()     // Catch: java.lang.Throwable -> L69
            r7.f(r8)     // Catch: java.lang.Throwable -> L69
            z0.a r8 = new z0.a     // Catch: java.lang.Throwable -> L69
            r9 = 15
            r8.<init>(r9)     // Catch: java.lang.Throwable -> L69
            java.lang.Object r9 = r8.f7780b     // Catch: java.lang.Throwable -> L69
            w1.a r9 = (p054w1.a) r9     // Catch: java.lang.Throwable -> L69
            if (r9 != 0) goto L44
            r8.f7780b = r7     // Catch: java.lang.Throwable -> L69
            goto L46
        L44:
            r8.c = r7     // Catch: java.lang.Throwable -> L69
        L46:
            r1.e r7 = r8.d()     // Catch: java.lang.Throwable -> L69
            r1.d r5 = r6.c(r7)     // Catch: java.lang.Throwable -> L69
            v1.a r6 = X1.k.P(r5)     // Catch: java.lang.Throwable -> L69
            if (r6 == 0) goto L65
            u1.d r6 = r6.d     // Catch: java.lang.Throwable -> L69
            r0.getClass()     // Catch: java.lang.Throwable -> L69
            if (r6 != 0) goto L5c
            goto L65
        L5c:
            u1.d r7 = p048u1.d.ON     // Catch: java.lang.Throwable -> L69
            if (r6 != r7) goto L62
            r6 = r1
            goto L63
        L62:
            r6 = r3
        L63:
            r0.f7624a = r6     // Catch: java.lang.Throwable -> L69
        L65:
            r5.a()
            goto L70
        L69:
            r6 = move-exception
            r6.printStackTrace()     // Catch: java.lang.Throwable -> L211
            if (r5 == 0) goto L70
            goto L65
        L70:
            java.lang.String r6 = "getPhotographyAidsZebraSettingInfo"
            com.panasonic.jp.flow.utils.Logger.d(r2, r6)
            x0.f r6 = r10.e     // Catch: java.lang.Throwable -> Lc9
            w1.a r7 = new w1.a     // Catch: java.lang.Throwable -> Lc9
            r7.<init>()     // Catch: java.lang.Throwable -> Lc9
            r7.a(r4)     // Catch: java.lang.Throwable -> Lc9
            w1.c r8 = p054w1.c.Command     // Catch: java.lang.Throwable -> Lc9
            r7.j(r8)     // Catch: java.lang.Throwable -> Lc9
            s1.V r8 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> Lc9
            r7.i(r8)     // Catch: java.lang.Throwable -> Lc9
            s1.E r8 = s1.E.Zebra     // Catch: java.lang.Throwable -> Lc9
            int r8 = r8.m4671getRawpVg5ArA()     // Catch: java.lang.Throwable -> Lc9
            r7.f(r8)     // Catch: java.lang.Throwable -> Lc9
            z0.a r8 = new z0.a     // Catch: java.lang.Throwable -> Lc9
            r9 = 15
            r8.<init>(r9)     // Catch: java.lang.Throwable -> Lc9
            java.lang.Object r9 = r8.f7780b     // Catch: java.lang.Throwable -> Lc9
            w1.a r9 = (p054w1.a) r9     // Catch: java.lang.Throwable -> Lc9
            if (r9 != 0) goto La2
            r8.f7780b = r7     // Catch: java.lang.Throwable -> Lc9
            goto La4
        La2:
            r8.c = r7     // Catch: java.lang.Throwable -> Lc9
        La4:
            r1.e r7 = r8.d()     // Catch: java.lang.Throwable -> Lc9
            r1.d r5 = r6.c(r7)     // Catch: java.lang.Throwable -> Lc9
            v1.d2 r6 = X1.k.S(r5)     // Catch: java.lang.Throwable -> Lc9
            if (r6 == 0) goto Lc5
            java.lang.Enum r6 = r6.d     // Catch: java.lang.Throwable -> Lc9
            v1.p2 r6 = (p051v1.p2) r6     // Catch: java.lang.Throwable -> Lc9
            r0.getClass()     // Catch: java.lang.Throwable -> Lc9
            if (r6 != 0) goto Lbc
            goto Lc5
        Lbc:
            v1.p2 r7 = p051v1.p2.OFF     // Catch: java.lang.Throwable -> Lc9
            if (r6 == r7) goto Lc2
            r6 = r1
            goto Lc3
        Lc2:
            r6 = r3
        Lc3:
            r0.c = r6     // Catch: java.lang.Throwable -> Lc9
        Lc5:
            r5.a()
            goto Ld0
        Lc9:
            r6 = move-exception
            r6.printStackTrace()     // Catch: java.lang.Throwable -> L20a
            if (r5 == 0) goto Ld0
            goto Lc5
        Ld0:
            java.lang.String r6 = "getPhotographyAidsPeakingSettingInfo"
            com.panasonic.jp.flow.utils.Logger.d(r2, r6)
            x0.f r6 = r10.e     // Catch: java.lang.Throwable -> L127
            w1.a r7 = new w1.a     // Catch: java.lang.Throwable -> L127
            r7.<init>()     // Catch: java.lang.Throwable -> L127
            r7.a(r4)     // Catch: java.lang.Throwable -> L127
            w1.c r8 = p054w1.c.Command     // Catch: java.lang.Throwable -> L127
            r7.j(r8)     // Catch: java.lang.Throwable -> L127
            s1.V r8 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L127
            r7.i(r8)     // Catch: java.lang.Throwable -> L127
            s1.E r8 = s1.E.Peaking     // Catch: java.lang.Throwable -> L127
            int r8 = r8.m4671getRawpVg5ArA()     // Catch: java.lang.Throwable -> L127
            r7.f(r8)     // Catch: java.lang.Throwable -> L127
            z0.a r8 = new z0.a     // Catch: java.lang.Throwable -> L127
            r9 = 15
            r8.<init>(r9)     // Catch: java.lang.Throwable -> L127
            java.lang.Object r9 = r8.f7780b     // Catch: java.lang.Throwable -> L127
            w1.a r9 = (p054w1.a) r9     // Catch: java.lang.Throwable -> L127
            if (r9 != 0) goto L102
            r8.f7780b = r7     // Catch: java.lang.Throwable -> L127
            goto L104
        L102:
            r8.c = r7     // Catch: java.lang.Throwable -> L127
        L104:
            r1.e r7 = r8.d()     // Catch: java.lang.Throwable -> L127
            r1.d r5 = r6.c(r7)     // Catch: java.lang.Throwable -> L127
            v1.a r6 = X1.k.R(r5)     // Catch: java.lang.Throwable -> L127
            if (r6 == 0) goto L123
            u1.d r6 = r6.d     // Catch: java.lang.Throwable -> L127
            r0.getClass()     // Catch: java.lang.Throwable -> L127
            if (r6 != 0) goto L11a
            goto L123
        L11a:
            u1.d r7 = p048u1.d.ON     // Catch: java.lang.Throwable -> L127
            if (r6 != r7) goto L120
            r6 = r1
            goto L121
        L120:
            r6 = r3
        L121:
            r0.d = r6     // Catch: java.lang.Throwable -> L127
        L123:
            r5.a()
            goto L12e
        L127:
            r6 = move-exception
            r6.printStackTrace()     // Catch: java.lang.Throwable -> L203
            if (r5 == 0) goto L12e
            goto L123
        L12e:
            java.lang.String r6 = "getPhotographyAidsFalseColorSettingInfo"
            com.panasonic.jp.flow.utils.Logger.d(r2, r6)
            x0.f r6 = r10.e     // Catch: java.lang.Throwable -> L184
            w1.a r7 = new w1.a     // Catch: java.lang.Throwable -> L184
            r7.<init>()     // Catch: java.lang.Throwable -> L184
            r7.a(r4)     // Catch: java.lang.Throwable -> L184
            w1.c r8 = p054w1.c.Command     // Catch: java.lang.Throwable -> L184
            r7.j(r8)     // Catch: java.lang.Throwable -> L184
            s1.V r8 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L184
            r7.i(r8)     // Catch: java.lang.Throwable -> L184
            s1.E r8 = s1.E.FalseColor     // Catch: java.lang.Throwable -> L184
            int r8 = r8.m4671getRawpVg5ArA()     // Catch: java.lang.Throwable -> L184
            r7.f(r8)     // Catch: java.lang.Throwable -> L184
            z0.a r8 = new z0.a     // Catch: java.lang.Throwable -> L184
            r9 = 15
            r8.<init>(r9)     // Catch: java.lang.Throwable -> L184
            java.lang.Object r9 = r8.f7780b     // Catch: java.lang.Throwable -> L184
            w1.a r9 = (p054w1.a) r9     // Catch: java.lang.Throwable -> L184
            if (r9 != 0) goto L160
            r8.f7780b = r7     // Catch: java.lang.Throwable -> L184
            goto L162
        L160:
            r8.c = r7     // Catch: java.lang.Throwable -> L184
        L162:
            r1.e r7 = r8.d()     // Catch: java.lang.Throwable -> L184
            r1.d r5 = r6.c(r7)     // Catch: java.lang.Throwable -> L184
            v1.a r6 = X1.k.M(r5)     // Catch: java.lang.Throwable -> L184
            if (r6 == 0) goto L180
            u1.d r6 = r6.d     // Catch: java.lang.Throwable -> L184
            r0.getClass()     // Catch: java.lang.Throwable -> L184
            if (r6 != 0) goto L178
            goto L180
        L178:
            u1.d r7 = p048u1.d.ON     // Catch: java.lang.Throwable -> L184
            if (r6 != r7) goto L17d
            goto L17e
        L17d:
            r1 = r3
        L17e:
            r0.f7627h = r1     // Catch: java.lang.Throwable -> L184
        L180:
            r5.a()
            goto L18b
        L184:
            r1 = move-exception
            r1.printStackTrace()     // Catch: java.lang.Throwable -> L1fc
            if (r5 == 0) goto L18b
            goto L180
        L18b:
            java.lang.String r1 = "getPhotographyAidsFalseColorMapInfo"
            com.panasonic.jp.flow.utils.Logger.d(r2, r1)
            x0.f r1 = r10.e     // Catch: java.lang.Throwable -> L1d7
            w1.a r6 = new w1.a     // Catch: java.lang.Throwable -> L1d7
            r6.<init>()     // Catch: java.lang.Throwable -> L1d7
            r6.a(r4)     // Catch: java.lang.Throwable -> L1d7
            w1.c r4 = p054w1.c.Command     // Catch: java.lang.Throwable -> L1d7
            r6.j(r4)     // Catch: java.lang.Throwable -> L1d7
            s1.V r4 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L1d7
            r6.i(r4)     // Catch: java.lang.Throwable -> L1d7
            s1.E r4 = s1.E.FalseColorMap     // Catch: java.lang.Throwable -> L1d7
            int r4 = r4.m4671getRawpVg5ArA()     // Catch: java.lang.Throwable -> L1d7
            r6.f(r4)     // Catch: java.lang.Throwable -> L1d7
            z0.a r4 = new z0.a     // Catch: java.lang.Throwable -> L1d7
            r7 = 15
            r4.<init>(r7)     // Catch: java.lang.Throwable -> L1d7
            java.lang.Object r7 = r4.f7780b     // Catch: java.lang.Throwable -> L1d7
            w1.a r7 = (p054w1.a) r7     // Catch: java.lang.Throwable -> L1d7
            if (r7 != 0) goto L1bd
            r4.f7780b = r6     // Catch: java.lang.Throwable -> L1d7
            goto L1bf
        L1bd:
            r4.c = r6     // Catch: java.lang.Throwable -> L1d7
        L1bf:
            r1.e r4 = r4.d()     // Catch: java.lang.Throwable -> L1d7
            r1.d r5 = r1.c(r4)     // Catch: java.lang.Throwable -> L1d7
            v1.d r1 = X1.k.N(r5)     // Catch: java.lang.Throwable -> L1d7
            if (r1 == 0) goto L1d3
            java.lang.Object r1 = r1.d     // Catch: java.lang.Throwable -> L1d7
            float[] r1 = (float[]) r1     // Catch: java.lang.Throwable -> L1d7
            r0.f7630k = r1     // Catch: java.lang.Throwable -> L1d7
        L1d3:
            r5.a()
            goto L1de
        L1d7:
            r0 = move-exception
            r0.printStackTrace()     // Catch: java.lang.Throwable -> L1f5
            if (r5 == 0) goto L1de
            goto L1d3
        L1de:
            java.lang.String r0 = "getVideoMicrophoneLevelSettingInfoAll"
            com.panasonic.jp.flow.utils.Logger.d(r2, r0)
            J0.G r0 = new J0.G
            r1 = 12
            r0.<init>(r1, r10, r3)
            android.os.Handler r10 = r10.f
            r10.post(r0)
            java.lang.String r10 = "onPhotographyAidsChanged"
            p038q0.a0.i(r10)
        L1f4:
            return
        L1f5:
            r10 = move-exception
            if (r5 == 0) goto L1fb
            r5.a()
        L1fb:
            throw r10
        L1fc:
            r10 = move-exception
            if (r5 == 0) goto L202
            r5.a()
        L202:
            throw r10
        L203:
            r10 = move-exception
            if (r5 == 0) goto L209
            r5.a()
        L209:
            throw r10
        L20a:
            r10 = move-exception
            if (r5 == 0) goto L210
            r5.a()
        L210:
            throw r10
        L211:
            r10 = move-exception
            if (r5 == 0) goto L217
            r5.a()
        L217:
            throw r10
    }

    private final void k() {
            r3 = this;
            q0.a0 r3 = r3.f6820b
            r3.getClass()
            w1.a r0 = new w1.a
            r0.<init>()
            r1 = 12
            r0.a(r1)
            w1.c r1 = p054w1.c.Command
            r0.j(r1)
            s1.V r1 = s1.V.LuxGetPramInfo
            r0.i(r1)
            s1.w r1 = s1.EnumC1007w.GetAll
            int r1 = r1.m4711getRawpVg5ArA()
            r0.f(r1)
            z0.a r1 = new z0.a
            r2 = 15
            r1.<init>(r2)
            java.lang.Object r2 = r1.f7780b
            w1.a r2 = (p054w1.a) r2
            if (r2 != 0) goto L32
            r1.f7780b = r0
            goto L34
        L32:
            r1.c = r0
        L34:
            r1.e r0 = r1.d()
            x0.f r1 = r3.e     // Catch: java.lang.Exception -> L61
            r1.d r0 = r1.c(r0)     // Catch: java.lang.Exception -> L61
            if (r0 == 0) goto L65
            v1.p0 r0 = X1.k.C(r0)     // Catch: java.lang.Exception -> L61
            if (r0 == 0) goto L65
            R1.a r1 = r0.f7462b     // Catch: java.lang.Exception -> L61
            v1.r1 r1 = (p051v1.C1061r1) r1     // Catch: java.lang.Exception -> L61
            java.lang.String r1 = r1.c     // Catch: java.lang.Exception -> L61
            r3.f6825g = r1     // Catch: java.lang.Exception -> L61
            R1.a r1 = r0.c     // Catch: java.lang.Exception -> L61
            v1.r1 r1 = (p051v1.C1061r1) r1     // Catch: java.lang.Exception -> L61
            java.lang.String r1 = r1.c     // Catch: java.lang.Exception -> L61
            r3.f6826h = r1     // Catch: java.lang.Exception -> L61
            R1.a r3 = r0.d     // Catch: java.lang.Exception -> L61
            v1.r1 r3 = (p051v1.C1061r1) r3     // Catch: java.lang.Exception -> L61
            java.lang.String r3 = r3.c     // Catch: java.lang.Exception -> L61
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Exception -> L61
            r0.f3810C = r3     // Catch: java.lang.Exception -> L61
            goto L65
        L61:
            r3 = move-exception
            r3.printStackTrace()
        L65:
            return
    }

    @Override // java.lang.Runnable
    public final void run() {
            r14 = this;
            int r0 = r14.f6819a
            switch(r0) {
                case 0: goto L525;
                case 1: goto L4ca;
                case 2: goto L382;
                case 3: goto L26f;
                case 4: goto L246;
                case 5: goto L1a1;
                case 6: goto L19d;
                case 7: goto Ldc;
                case 8: goto La4;
                case 9: goto La0;
                case 10: goto L9c;
                case 11: goto L98;
                case 12: goto L94;
                case 13: goto L90;
                case 14: goto L8c;
                case 15: goto L88;
                case 16: goto L82;
                case 17: goto L7c;
                case 18: goto L78;
                case 19: goto L74;
                case 20: goto L70;
                default: goto L5;
            }
        L5:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            w1.a r0 = new w1.a
            r0.<init>()
            r1 = 12
            r0.a(r1)
            w1.c r1 = p054w1.c.Command
            r0.j(r1)
            s1.V r1 = s1.V.LuxGetPramInfo
            r0.i(r1)
            s1.s r1 = s1.EnumC1003s.ModelSNInfo
            int r1 = r1.m4707getRawpVg5ArA()
            r0.f(r1)
            z0.a r1 = new z0.a
            r2 = 15
            r1.<init>(r2)
            java.lang.Object r2 = r1.f7780b
            w1.a r2 = (p054w1.a) r2
            if (r2 != 0) goto L37
            r1.f7780b = r0
            goto L39
        L37:
            r1.c = r0
        L39:
            r1.e r0 = r1.d()
            x0.f r14 = r14.e     // Catch: java.lang.Exception -> L6b
            r1.d r14 = r14.c(r0)     // Catch: java.lang.Exception -> L6b
            if (r14 == 0) goto L6f
            v1.x r14 = X1.k.w(r14)     // Catch: java.lang.Exception -> L6b
            if (r14 == 0) goto L6f
            java.lang.Object r14 = r14.c     // Catch: java.lang.Exception -> L6b
            byte[] r14 = (byte[]) r14     // Catch: java.lang.Exception -> L6b
            java.lang.String r14 = N0.n.a(r14)     // Catch: java.lang.Exception -> L6b
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Exception -> L6b
            r0.f3819N = r14     // Catch: java.lang.Exception -> L6b
            java.lang.StringBuilder r0 = new java.lang.StringBuilder     // Catch: java.lang.Exception -> L6b
            java.lang.String r1 = "cameraSerialNumber="
            r0.<init>(r1)     // Catch: java.lang.Exception -> L6b
            r0.append(r14)     // Catch: java.lang.Exception -> L6b
            java.lang.String r14 = r0.toString()     // Catch: java.lang.Exception -> L6b
            java.lang.String r0 = "setCameraSerialNumber"
            com.panasonic.jp.flow.utils.Logger.d(r0, r14)     // Catch: java.lang.Exception -> L6b
            goto L6f
        L6b:
            r14 = move-exception
            r14.printStackTrace()
        L6f:
            return
        L70:
            r14.k()
            return
        L74:
            r14.j()
            return
        L78:
            r14.i()
            return
        L7c:
            q0.a0 r14 = r14.f6820b
            r14.c()
            return
        L82:
            q0.a0 r14 = r14.f6820b
            r14.e()
            return
        L88:
            r14.h()
            return
        L8c:
            r14.g()
            return
        L90:
            r14.f()
            return
        L94:
            r14.b()
            return
        L98:
            r14.e()
            return
        L9c:
            r14.d()
            return
        La0:
            r14.c()
            return
        La4:
            java.lang.String r0 = "setErrorNotifyEnable response="
            q0.a0 r14 = r14.f6820b
            x0.f r14 = r14.e
            if (r14 != 0) goto Lad
            goto Ldb
        Lad:
            r1.e r1 = q2.c.G()     // Catch: java.lang.Exception -> Lbd
            r1.d r14 = r14.c(r1)     // Catch: java.lang.Exception -> Lbd
            if (r14 != 0) goto Lbf
            if (r14 == 0) goto Ldb
        Lb9:
            r14.a()     // Catch: java.lang.Exception -> Lbd
            goto Ldb
        Lbd:
            r14 = move-exception
            goto Ld8
        Lbf:
            java.lang.String r1 = "NotifyCenter"
            java.lang.StringBuilder r2 = new java.lang.StringBuilder     // Catch: java.lang.Throwable -> Ld3
            r2.<init>(r0)     // Catch: java.lang.Throwable -> Ld3
            s1.X r0 = r14.f7139b     // Catch: java.lang.Throwable -> Ld3
            r2.append(r0)     // Catch: java.lang.Throwable -> Ld3
            java.lang.String r0 = r2.toString()     // Catch: java.lang.Throwable -> Ld3
            com.panasonic.jp.flow.utils.Logger.d(r1, r0)     // Catch: java.lang.Throwable -> Ld3
            goto Lb9
        Ld3:
            r0 = move-exception
            r14.a()     // Catch: java.lang.Exception -> Lbd
            throw r0     // Catch: java.lang.Exception -> Lbd
        Ld8:
            r14.printStackTrace()
        Ldb:
            return
        Ldc:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            r0 = 0
            x0.f r14 = r14.e     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            w1.a r1 = new w1.a     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r1.<init>()     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r2 = 4
            r1.a(r2)     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            w1.c r2 = p054w1.c.Command     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r1.j(r2)     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            s1.V r2 = s1.V.LuxGetAFInfo     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r1.i(r2)     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            s1.g r2 = s1.EnumC0992g.GetAll     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            int r2 = r2.m4695getRawpVg5ArA()     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r1.f(r2)     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            z0.a r2 = new z0.a     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r3 = 15
            r2.<init>(r3)     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            java.lang.Object r3 = r2.f7780b     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            w1.a r3 = (p054w1.a) r3     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            if (r3 != 0) goto L110
            r2.f7780b = r1     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            goto L112
        L110:
            r2.c = r1     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
        L112:
            r1.e r1 = r2.d()     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            r1.d r14 = r14.c(r1)     // Catch: java.lang.Throwable -> L187 java.lang.Exception -> L18c
            v1.N r1 = X1.k.k(r14)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            if (r1 != 0) goto L125
        L120:
            r14.a()
            goto L196
        L125:
            com.panasonic.jp.flow.app.FlowApp r2 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            y0.g r2 = r2.f3825i     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.d r3 = r1.f7384b     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            int r4 = r3.c     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            java.lang.Object r3 = r3.d     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.s[] r3 = (p051v1.EnumC1062s[]) r3     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            com.panasonic.jp.flow.data.af.AFZoneData r5 = r2.f7576k     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            if (r4 <= 0) goto L139
            r5.setAfZoneFullData(r3)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            goto L13c
        L139:
            r5.setAfZoneFullData(r0)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
        L13c:
            v1.d r3 = r1.f7383a     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            java.lang.Object r3 = r3.d     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.S r3 = (p051v1.S) r3     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.P r4 = r1.d     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r2.W(r3, r4, r0)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.M r0 = r1.c     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            java.util.ArrayList r4 = r0.f7382h     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.d r3 = r1.f     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            java.lang.Object r3 = r3.d     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r5 = r3
            v1.h r5 = (p051v1.EnumC1030h) r5     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            short r3 = r0.f7380b     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r6 = 65535(0xffff, float:9.1834E-41)
            r7 = r3 & r6
            short r3 = r0.c     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r8 = r3 & r6
            short r3 = r0.d     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r9 = r3 & r6
            short r3 = r0.e     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r10 = r3 & r6
            short r3 = r0.f     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r11 = r3 & r6
            short r0 = r0.f7381g     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r0 = r0 & r6
            r3 = r2
            r6 = r7
            r7 = r8
            r8 = r9
            r9 = r10
            r10 = r11
            r11 = r0
            r3.S(r4, r5, r6, r7, r8, r9, r10, r11)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            v1.O r0 = r1.f7385g     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            java.util.ArrayList r0 = r0.d     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            r2.T(r0)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            java.lang.String r0 = "onAFStatesChanged"
            p038q0.a0.i(r0)     // Catch: java.lang.Throwable -> L183 java.lang.Exception -> L185
            goto L120
        L183:
            r0 = move-exception
            goto L197
        L185:
            r0 = move-exception
            goto L190
        L187:
            r14 = move-exception
            r13 = r0
            r0 = r14
            r14 = r13
            goto L197
        L18c:
            r14 = move-exception
            r13 = r0
            r0 = r14
            r14 = r13
        L190:
            r0.printStackTrace()     // Catch: java.lang.Throwable -> L183
            if (r14 == 0) goto L196
            goto L120
        L196:
            return
        L197:
            if (r14 == 0) goto L19c
            r14.a()
        L19c:
            throw r0
        L19d:
            r14.a()
            return
        L1a1:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            java.lang.String r0 = "data.getColorSetting().getColorSetting()===="
            r1 = 0
            x0.f r14 = r14.e     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            w1.a r2 = new w1.a     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r2.<init>()     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r3 = 4
            r2.a(r3)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            w1.c r3 = p054w1.c.Command     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r2.j(r3)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            s1.V r3 = s1.V.LuxGetRecInfo     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r2.i(r3)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            s1.i r3 = s1.EnumC0994i.GetAll     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            int r3 = r3.m4697getRawpVg5ArA()     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r2.f(r3)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            z0.a r3 = new z0.a     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r4 = 15
            r3.<init>(r4)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.Object r4 = r3.f7780b     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            w1.a r4 = (p054w1.a) r4     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            if (r4 != 0) goto L1d7
            r3.f7780b = r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            goto L1d9
        L1d7:
            r3.c = r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
        L1d9:
            r1.e r2 = r3.d()     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r1.d r1 = r14.c(r2)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.J r14 = X1.k.j(r1)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            if (r14 != 0) goto L1eb
        L1e7:
            r1.a()
            goto L23f
        L1eb:
            java.io.PrintStream r2 = java.lang.System.out     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.StringBuilder r3 = new java.lang.StringBuilder     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r3.<init>(r0)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.I r0 = r14.f7370i     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.x0 r0 = r0.d     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r3.append(r0)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.String r0 = r3.toString()     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r2.println(r0)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.I r2 = r14.f7370i     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.x0 r2 = r2.d     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r0.f3829m = r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            y0.g r0 = r0.f3825i     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.d r2 = r14.f7371j     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.Object r2 = r2.d     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.f r2 = (p051v1.EnumC1024f) r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.a r3 = r14.f7372k     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            u1.d r3 = r3.d     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r0.f7581p = r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r0.f7582q = r3     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            com.panasonic.jp.flow.data.af.AFFaceData r4 = r0.f7577l     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r4.eyesFrameTypeValue = r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r4.eyesCrosshairSwitch = r3     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r0.V()     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.d r2 = r14.f7367b     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.Object r2 = r2.d     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.u r2 = (p051v1.EnumC1068u) r2     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.d r14 = r14.f7366a     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.Object r14 = r14.d     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            v1.V0 r14 = (p051v1.V0) r14     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            r0.U(r2, r14)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            java.lang.String r14 = "onAFStatesChanged"
            p038q0.a0.i(r14)     // Catch: java.lang.Throwable -> L236 java.lang.Exception -> L238
            goto L1e7
        L236:
            r14 = move-exception
            goto L240
        L238:
            r14 = move-exception
            r14.printStackTrace()     // Catch: java.lang.Throwable -> L236
            if (r1 == 0) goto L23f
            goto L1e7
        L23f:
            return
        L240:
            if (r1 == 0) goto L245
            r1.a()
        L245:
            throw r14
        L246:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            com.panasonic.jp.flow.data.para.VolumeData r0 = r0.f3831o
            x0.f r14 = r14.e
            r0.updateAll(r14)
            java.lang.StringBuilder r14 = new java.lang.StringBuilder
            java.lang.String r1 = "当前音量="
            r14.<init>(r1)
            int r0 = r0.maxVolume
            r14.append(r0)
            java.lang.String r14 = r14.toString()
            java.lang.String r0 = "NotifyCenter"
            com.panasonic.jp.flow.utils.Logger.d(r0, r14)
            java.lang.String r14 = "onFlowVolumeChanged"
            p038q0.a0.i(r14)
            return
        L26f:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.k r0 = r0.f3826j
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r1 = r0.d
            java.util.List r1 = r1.getFrameAspectRadioList()
            r2 = 0
            r3 = 0
            r5 = 0
            if (r1 == 0) goto L290
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r1 = r0.d
            java.util.List r1 = r1.getFrameAspectRadioList()
            boolean r1 = r1.isEmpty()
            if (r1 == 0) goto L300
        L290:
            java.lang.String r1 = "getFrameCapabilityInfo"
            java.lang.String r6 = "获取FrameAspectRadioList"
            com.panasonic.jp.flow.utils.Logger.d(r1, r6)
            java.util.ArrayList r1 = new java.util.ArrayList
            r1.<init>()
            x0.f r6 = r14.e
            s1.D r7 = s1.D.Frame1AspectRatioSetting
            long r8 = r7.getRawUpper()
            kotlin.jvm.internal.G r6 = r6.b(r8)
            if (r6 == 0) goto L300
            long r7 = r7.getRawUpper()
            y0.a r6 = r6.c(r7)
            if (r6 == 0) goto L300
            long r7 = r6.f7565b
            int r7 = (r7 > r3 ? 1 : (r7 == r3 ? 0 : -1))
            if (r7 <= 0) goto L300
            y0.e r6 = r6.a(r5)
            int r7 = r6.c
            if (r7 <= 0) goto L300
            monitor-enter(r14)
            short[] r6 = r6.e     // Catch: java.lang.Throwable -> L2f5
            int r7 = r6.length     // Catch: java.lang.Throwable -> L2f5
            r8 = r5
        L2c7:
            if (r8 >= r7) goto L2f7
            short r9 = r6[r8]     // Catch: java.lang.Throwable -> L2f5
            v1.A0 r10 = p051v1.B0.Companion     // Catch: java.lang.Throwable -> L2f5
            r10.getClass()     // Catch: java.lang.Throwable -> L2f5
            J1.a r10 = p051v1.B0.getEntries()     // Catch: java.lang.Throwable -> L2f5
            java.util.Iterator r10 = r10.iterator()     // Catch: java.lang.Throwable -> L2f5
        L2d8:
            boolean r11 = r10.hasNext()     // Catch: java.lang.Throwable -> L2f5
            if (r11 == 0) goto L2ec
            java.lang.Object r11 = r10.next()     // Catch: java.lang.Throwable -> L2f5
            r12 = r11
            v1.B0 r12 = (p051v1.B0) r12     // Catch: java.lang.Throwable -> L2f5
            short r12 = r12.m4719getRawMh2AYeg()     // Catch: java.lang.Throwable -> L2f5
            if (r12 != r9) goto L2d8
            goto L2ed
        L2ec:
            r11 = r2
        L2ed:
            v1.B0 r11 = (p051v1.B0) r11     // Catch: java.lang.Throwable -> L2f5
            r1.add(r11)     // Catch: java.lang.Throwable -> L2f5
            int r8 = r8 + 1
            goto L2c7
        L2f5:
            r0 = move-exception
            goto L2fe
        L2f7:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r6 = r0.d     // Catch: java.lang.Throwable -> L2f5
            r6.setFrameAspectRadioList(r1)     // Catch: java.lang.Throwable -> L2f5
            monitor-exit(r14)     // Catch: java.lang.Throwable -> L2f5
            goto L300
        L2fe:
            monitor-exit(r14)     // Catch: java.lang.Throwable -> L2f5
            throw r0
        L300:
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r1 = r0.d
            java.util.List r1 = r1.getFrameColorList()
            if (r1 == 0) goto L314
            com.panasonic.jp.flow.data.frame.FrameCoordinateInformationData r1 = r0.d
            java.util.List r1 = r1.getFrameColorList()
            boolean r1 = r1.isEmpty()
            if (r1 == 0) goto L381
        L314:
            java.lang.String r1 = "getFrameCapabilityInfo"
            java.lang.String r6 = "获取FrameColorList"
            com.panasonic.jp.flow.utils.Logger.d(r1, r6)
            java.util.ArrayList r1 = new java.util.ArrayList
            r1.<init>()
            x0.f r6 = r14.e
            s1.D r7 = s1.D.Frame1ColorSetting
            long r8 = r7.getRawUpper()
            kotlin.jvm.internal.G r6 = r6.b(r8)
            if (r6 == 0) goto L381
            long r7 = r7.getRawUpper()
            y0.a r6 = r6.c(r7)
            if (r6 == 0) goto L381
            long r7 = r6.f7565b
            int r3 = (r7 > r3 ? 1 : (r7 == r3 ? 0 : -1))
            if (r3 <= 0) goto L381
            y0.e r3 = r6.a(r5)
            int r4 = r3.c
            if (r4 <= 0) goto L381
            monitor-enter(r14)
            short[] r3 = r3.e     // Catch: java.lang.Throwable -> L378
            int r4 = r3.length     // Catch: java.lang.Throwable -> L378
        L34a:
            if (r5 >= r4) goto L37a
            short r6 = r3[r5]     // Catch: java.lang.Throwable -> L378
            v1.w0 r7 = p051v1.EnumC1078x0.Companion     // Catch: java.lang.Throwable -> L378
            r7.getClass()     // Catch: java.lang.Throwable -> L378
            J1.a r7 = p051v1.EnumC1078x0.getEntries()     // Catch: java.lang.Throwable -> L378
            java.util.Iterator r7 = r7.iterator()     // Catch: java.lang.Throwable -> L378
        L35b:
            boolean r8 = r7.hasNext()     // Catch: java.lang.Throwable -> L378
            if (r8 == 0) goto L36f
            java.lang.Object r8 = r7.next()     // Catch: java.lang.Throwable -> L378
            r9 = r8
            v1.x0 r9 = (p051v1.EnumC1078x0) r9     // Catch: java.lang.Throwable -> L378
            short r9 = r9.m4775getRawMh2AYeg()     // Catch: java.lang.Throwable -> L378
            if (r9 != r6) goto L35b
            goto L370
        L36f:
            r8 = r2
        L370:
            v1.x0 r8 = (p051v1.EnumC1078x0) r8     // Catch: java.lang.Throwable -> L378
            r1.add(r8)     // Catch: java.lang.Throwable -> L378
            int r5 = r5 + 1
            goto L34a
        L378:
            r0 = move-exception
            goto L37f
        L37a:
            r0.b(r1)     // Catch: java.lang.Throwable -> L378
            monitor-exit(r14)     // Catch: java.lang.Throwable -> L378
            goto L381
        L37f:
            monitor-exit(r14)     // Catch: java.lang.Throwable -> L378
            throw r0
        L381:
            return
        L382:
            q0.a0 r14 = r14.f6820b
            x0.f r0 = r14.e
            if (r0 != 0) goto L38a
            goto L4c2
        L38a:
            java.util.ArrayList r0 = r14.f6830l
            r0.clear()
            java.util.ArrayList r0 = r14.f6831m
            r0.clear()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.l r0 = r0.f3827k
            r1 = 0
            x0.f r2 = r14.e     // Catch: java.lang.Throwable -> L42c
            w1.a r3 = new w1.a     // Catch: java.lang.Throwable -> L42c
            r3.<init>()     // Catch: java.lang.Throwable -> L42c
            r4 = 4
            r3.a(r4)     // Catch: java.lang.Throwable -> L42c
            w1.c r4 = p054w1.c.Command     // Catch: java.lang.Throwable -> L42c
            r3.j(r4)     // Catch: java.lang.Throwable -> L42c
            s1.V r4 = s1.V.LuxGetPramInfo     // Catch: java.lang.Throwable -> L42c
            r3.i(r4)     // Catch: java.lang.Throwable -> L42c
            s1.A r4 = s1.A.GetLutInfo     // Catch: java.lang.Throwable -> L42c
            int r4 = r4.m4667getRawpVg5ArA()     // Catch: java.lang.Throwable -> L42c
            r3.f(r4)     // Catch: java.lang.Throwable -> L42c
            z0.a r4 = new z0.a     // Catch: java.lang.Throwable -> L42c
            r5 = 15
            r4.<init>(r5)     // Catch: java.lang.Throwable -> L42c
            java.lang.Object r5 = r4.f7780b     // Catch: java.lang.Throwable -> L42c
            w1.a r5 = (p054w1.a) r5     // Catch: java.lang.Throwable -> L42c
            if (r5 != 0) goto L3c7
            r4.f7780b = r3     // Catch: java.lang.Throwable -> L42c
            goto L3c9
        L3c7:
            r4.c = r3     // Catch: java.lang.Throwable -> L42c
        L3c9:
            r1.e r3 = r4.d()     // Catch: java.lang.Throwable -> L42c
            r1.d r1 = r2.c(r3)     // Catch: java.lang.Throwable -> L42c
            v1.O r2 = X1.k.D(r1)     // Catch: java.lang.Throwable -> L42c
            if (r2 == 0) goto L4b8
            java.util.List r3 = r0.d     // Catch: java.lang.Throwable -> L42c
            r4 = 65535(0xffff, float:9.1834E-41)
            r5 = 0
            if (r3 == 0) goto L439
            r3 = r5
        L3e0:
            java.util.List r6 = r0.d     // Catch: java.lang.Throwable -> L42c
            int r6 = r6.size()     // Catch: java.lang.Throwable -> L42c
            if (r3 >= r6) goto L435
            java.util.List r6 = r0.d     // Catch: java.lang.Throwable -> L42c
            java.lang.Object r6 = r6.get(r3)     // Catch: java.lang.Throwable -> L42c
            java.lang.Integer r6 = (java.lang.Integer) r6     // Catch: java.lang.Throwable -> L42c
            int r6 = r6.intValue()     // Catch: java.lang.Throwable -> L42c
            r7 = r5
        L3f5:
            java.util.ArrayList r8 = r2.d     // Catch: java.lang.Throwable -> L42c
            int r8 = r8.size()     // Catch: java.lang.Throwable -> L42c
            if (r7 >= r8) goto L432
            java.util.ArrayList r8 = r2.d     // Catch: java.lang.Throwable -> L42c
            java.lang.Object r8 = r8.get(r7)     // Catch: java.lang.Throwable -> L42c
            v1.s1 r8 = (p051v1.C1064s1) r8     // Catch: java.lang.Throwable -> L42c
            short r9 = r8.f7469a     // Catch: java.lang.Throwable -> L42c
            r9 = r9 & r4
            if (r6 != r9) goto L42f
            com.panasonic.jp.flow.data.lut.LutInfoBean$DataBean$DataListBean r9 = new com.panasonic.jp.flow.data.lut.LutInfoBean$DataBean$DataListBean     // Catch: java.lang.Throwable -> L42c
            r9.<init>()     // Catch: java.lang.Throwable -> L42c
            java.lang.String r10 = r8.f7470b     // Catch: java.lang.Throwable -> L42c
            r9.setLutName(r10)     // Catch: java.lang.Throwable -> L42c
            short r10 = r8.f7469a     // Catch: java.lang.Throwable -> L42c
            r10 = r10 & r4
            r9.setLutId(r10)     // Catch: java.lang.Throwable -> L42c
            short r10 = r8.c     // Catch: java.lang.Throwable -> L42c
            r10 = r10 & r4
            r9.setLutType(r10)     // Catch: java.lang.Throwable -> L42c
            short r8 = r8.d     // Catch: java.lang.Throwable -> L42c
            r8 = r8 & r4
            r9.setVisibility(r8)     // Catch: java.lang.Throwable -> L42c
            java.util.ArrayList r8 = r14.f6830l     // Catch: java.lang.Throwable -> L42c
            r8.add(r9)     // Catch: java.lang.Throwable -> L42c
            goto L42f
        L42c:
            r14 = move-exception
            goto L4bc
        L42f:
            int r7 = r7 + 1
            goto L3f5
        L432:
            int r3 = r3 + 1
            goto L3e0
        L435:
            java.util.ArrayList r3 = r14.f6830l     // Catch: java.lang.Throwable -> L42c
            r0.f = r3     // Catch: java.lang.Throwable -> L42c
        L439:
            java.util.List r3 = r0.e     // Catch: java.lang.Throwable -> L42c
            if (r3 == 0) goto L493
            r3 = r5
        L43e:
            java.util.List r6 = r0.e     // Catch: java.lang.Throwable -> L42c
            int r6 = r6.size()     // Catch: java.lang.Throwable -> L42c
            if (r3 >= r6) goto L48f
            java.util.List r6 = r0.e     // Catch: java.lang.Throwable -> L42c
            java.lang.Object r6 = r6.get(r3)     // Catch: java.lang.Throwable -> L42c
            java.lang.Integer r6 = (java.lang.Integer) r6     // Catch: java.lang.Throwable -> L42c
            int r6 = r6.intValue()     // Catch: java.lang.Throwable -> L42c
            r7 = r5
        L453:
            java.util.ArrayList r8 = r2.d     // Catch: java.lang.Throwable -> L42c
            int r8 = r8.size()     // Catch: java.lang.Throwable -> L42c
            if (r7 >= r8) goto L48c
            java.util.ArrayList r8 = r2.d     // Catch: java.lang.Throwable -> L42c
            java.lang.Object r8 = r8.get(r7)     // Catch: java.lang.Throwable -> L42c
            v1.s1 r8 = (p051v1.C1064s1) r8     // Catch: java.lang.Throwable -> L42c
            short r9 = r8.f7469a     // Catch: java.lang.Throwable -> L42c
            r9 = r9 & r4
            if (r6 != r9) goto L489
            com.panasonic.jp.flow.data.lut.LutInfoBean$DataBean$DataListBean r9 = new com.panasonic.jp.flow.data.lut.LutInfoBean$DataBean$DataListBean     // Catch: java.lang.Throwable -> L42c
            r9.<init>()     // Catch: java.lang.Throwable -> L42c
            java.lang.String r10 = r8.f7470b     // Catch: java.lang.Throwable -> L42c
            r9.setLutName(r10)     // Catch: java.lang.Throwable -> L42c
            short r10 = r8.f7469a     // Catch: java.lang.Throwable -> L42c
            r10 = r10 & r4
            r9.setLutId(r10)     // Catch: java.lang.Throwable -> L42c
            short r10 = r8.c     // Catch: java.lang.Throwable -> L42c
            r10 = r10 & r4
            r9.setLutType(r10)     // Catch: java.lang.Throwable -> L42c
            short r8 = r8.d     // Catch: java.lang.Throwable -> L42c
            r8 = r8 & r4
            r9.setVisibility(r8)     // Catch: java.lang.Throwable -> L42c
            java.util.ArrayList r8 = r14.f6831m     // Catch: java.lang.Throwable -> L42c
            r8.add(r9)     // Catch: java.lang.Throwable -> L42c
        L489:
            int r7 = r7 + 1
            goto L453
        L48c:
            int r3 = r3 + 1
            goto L43e
        L48f:
            java.util.ArrayList r14 = r14.f6831m     // Catch: java.lang.Throwable -> L42c
            r0.f7623g = r14     // Catch: java.lang.Throwable -> L42c
        L493:
            r14 = r5
        L494:
            java.util.ArrayList r3 = r2.d     // Catch: java.lang.Throwable -> L42c
            int r3 = r3.size()     // Catch: java.lang.Throwable -> L42c
            if (r14 >= r3) goto L4b8
            java.util.ArrayList r3 = r2.d     // Catch: java.lang.Throwable -> L42c
            java.lang.Object r3 = r3.get(r14)     // Catch: java.lang.Throwable -> L42c
            v1.s1 r3 = (p051v1.C1064s1) r3     // Catch: java.lang.Throwable -> L42c
            short r6 = r3.f7469a     // Catch: java.lang.Throwable -> L42c
            r6 = r6 & r4
            r7 = 1
            if (r6 != r7) goto L4b3
            short r3 = r3.d     // Catch: java.lang.Throwable -> L42c
            r3 = r3 & r4
            r6 = 2
            if (r3 != r6) goto L4b3
            r0.c = r5     // Catch: java.lang.Throwable -> L42c
            goto L4b8
        L4b3:
            r0.c = r7     // Catch: java.lang.Throwable -> L42c
            int r14 = r14 + 1
            goto L494
        L4b8:
            r1.a()
            goto L4c2
        L4bc:
            r14.printStackTrace()     // Catch: java.lang.Throwable -> L4c3
            if (r1 == 0) goto L4c2
            goto L4b8
        L4c2:
            return
        L4c3:
            r14 = move-exception
            if (r1 == 0) goto L4c9
            r1.a()
        L4c9:
            throw r14
        L4ca:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            w1.a r0 = new w1.a
            r0.<init>()
            r1 = 12
            r0.a(r1)
            w1.c r1 = p054w1.c.Command
            r0.j(r1)
            s1.V r1 = s1.V.LuxGetPramInfo
            r0.i(r1)
            s1.s r1 = s1.EnumC1003s.ModelDestinationInfo
            int r1 = r1.m4707getRawpVg5ArA()
            r0.f(r1)
            z0.a r1 = new z0.a
            r2 = 15
            r1.<init>(r2)
            java.lang.Object r2 = r1.f7780b
            w1.a r2 = (p054w1.a) r2
            if (r2 != 0) goto L4fc
            r1.f7780b = r0
            goto L4fe
        L4fc:
            r1.c = r0
        L4fe:
            r1.e r0 = r1.d()
            x0.f r14 = r14.e     // Catch: java.lang.Exception -> L520
            r1.d r14 = r14.c(r0)     // Catch: java.lang.Exception -> L520
            if (r14 == 0) goto L524
            v1.x r14 = X1.k.x(r14)     // Catch: java.lang.Exception -> L520
            if (r14 == 0) goto L524
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R     // Catch: java.lang.Exception -> L520
            java.lang.Object r14 = r14.c     // Catch: java.lang.Exception -> L520
            v1.z0 r14 = (p051v1.EnumC1084z0) r14     // Catch: java.lang.Exception -> L520
            r0.getClass()     // Catch: java.lang.Exception -> L520
            java.lang.String r14 = r14.getDestination()     // Catch: java.lang.Exception -> L520
            r0.f3811E = r14     // Catch: java.lang.Exception -> L520
            goto L524
        L520:
            r14 = move-exception
            r14.printStackTrace()
        L524:
            return
        L525:
            q0.a0 r14 = r14.f6820b
            r14.getClass()
            com.panasonic.jp.flow.app.FlowApp r0 = com.panasonic.jp.flow.app.FlowApp.f3797R
            y0.i r0 = r0.f3824h
            x0.f r14 = r14.e
            r0.s(r14)
            r0.t(r14)
            r0.q(r14)
            r0.r(r14)
            E0.i r14 = E0.EnumC0343i.ALL
            int r14 = r14.ordinal()
            java.lang.String r0 = "onCameraInfoSettingChanged"
            p038q0.a0.h(r14, r0)
            return
    }
}
