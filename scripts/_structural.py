"""
Genuinely structural building blocks (no behavioral *, /, % on datapath).
Everything lowers to half_adder / full_adder leaf cells.

Design: emit ONE flat self-contained module per call. Submodules used inside
get unique suffix names so a file never has duplicate module definitions.
"""

def leaf_adders():
    return (
"module half_adder(input a, input b, output sum, output carry);\n"
"    assign sum   = a ^ b;\n"
"    assign carry = a & b;\n"
"endmodule\n\n"
"module full_adder(input a, input b, input cin, output sum, output cout);\n"
"    wire s0, c0, c1;\n"
"    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));\n"
"    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));\n"
"    assign cout = c0 | c1;\n"
"endmodule\n")

def ripple_adder(w, name):
    L=[f"module {name}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(c[{i}]),.sum(sum[{i}]),.cout(c[{i+1}]));")
    L.append(f"    assign cout=c[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"

def cond_inc(w, name):
    """y = a + add  (add is a single bit), structural half-adder chain."""
    L=[f"module {name}(input [{w-1}:0] a, input add, output [{w-1}:0] y, output cout);"]
    L.append(f"    wire [{w}:0] c; assign c[0]=add;")
    for i in range(w):
        L.append(f"    half_adder h{i}(.a(a[{i}]),.b(c[{i}]),.sum(y[{i}]),.carry(c[{i+1}]));")
    L.append(f"    assign cout=c[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"

# ---------------- unsigned array core (returns module body only) ----------
def _array_core(w, name, rca_name):
    """Unsigned array multiplier using AND partial products + ripple-add chain.
    Instantiates rca_name (a 2w ripple adder declared elsewhere in the file)."""
    P=2*w
    L=[f"module {name}(input [{w-1}:0] a, input [{w-1}:0] b, output [{P-1}:0] product);"]
    for i in range(w):
        for j in range(w):
            L.append(f"    wire pp{i}_{j} = a[{j}] & b[{i}];")
    for i in range(w):
        bits=[]
        for k in range(P):
            jj=k-i
            bits.append(f"pp{i}_{jj}" if 0<=jj<w else "1'b0")
        L.append(f"    wire [{P-1}:0] row{i} = {{{', '.join(reversed(bits))}}};")
    acc="row0"
    for i in range(1,w):
        nxt=f"acc{i}"
        L.append(f"    wire [{P-1}:0] {nxt}; wire co{i};")
        L.append(f"    {rca_name} add{i}(.a({acc}),.b(row{i}),.cin(1'b0),.sum({nxt}),.cout(co{i}));")
        acc=nxt
    L.append(f"    assign product = {acc};")
    L.append("endmodule")
    return "\n".join(L)+"\n"

def _csa_core(w, name, rca_name):
    """Wallace/Dadda-style 3:2 compressor reduction core."""
    P=2*w
    L=[f"module {name}(input [{w-1}:0] a, input [{w-1}:0] b, output [{P-1}:0] product);"]
    for i in range(w):
        for j in range(w):
            L.append(f"    wire pp{i}_{j} = a[{j}] & b[{i}];")
    cols={k:[] for k in range(P)}
    for i in range(w):
        for j in range(w):
            cols[i+j].append(f"pp{i}_{j}")
    uid=[0]
    def nw():
        uid[0]+=1; return f"w{uid[0]}"
    for k in range(P):
        while len(cols[k])>2:
            a3,b3,c3=cols[k][0],cols[k][1],cols[k][2]; rest=cols[k][3:]
            s=nw(); cy=nw()
            L.append(f"    wire {s}, {cy};")
            L.append(f"    full_adder fc{uid[0]}(.a({a3}),.b({b3}),.cin({c3}),.sum({s}),.cout({cy}));")
            cols[k]=rest+[s]
            if k+1<P: cols[k+1].append(cy)
    rowA=[]; rowB=[]
    for k in range(P):
        t=cols[k]
        rowA.append(t[0] if len(t)>=1 else "1'b0")
        rowB.append(t[1] if len(t)>=2 else "1'b0")
    L.append(f"    wire [{P-1}:0] opA = {{{', '.join(reversed(rowA))}}};")
    L.append(f"    wire [{P-1}:0] opB = {{{', '.join(reversed(rowB))}}};")
    L.append(f"    wire co_f;")
    L.append(f"    {rca_name} final_add(.a(opA),.b(opB),.cin(1'b0),.sum(product),.cout(co_f));")
    L.append("endmodule")
    return "\n".join(L)+"\n"

# ---------------- public: full self-contained files ----------------------
def unsigned_multiplier_file(w, top, core="array"):
    P=2*w
    coregen=_array_core if core=="array" else _csa_core
    parts=[]
    parts.append(coregen(w, top, f"rca{P}"))
    parts.append(ripple_adder(P, f"rca{P}"))
    parts.append(leaf_adders())
    return "\n".join(parts)

def signed_multiplier_file(w, top, core="array"):
    """
    Structural signed multiply: magnitude via XOR+cond-inc, unsigned core,
    conditional negate of the 2w product. No * anywhere.
    """
    P=2*w
    coregen=_array_core if core=="array" else _csa_core
    L=[f"module {top}(input signed [{w-1}:0] a, input signed [{w-1}:0] b, output signed [{P-1}:0] product);"]
    L.append(f"    wire sa=a[{w-1}], sb=b[{w-1}];")
    L.append(f"    wire [{w-1}:0] a_inv = a ^ {{{w}{{sa}}}};")
    L.append(f"    wire [{w-1}:0] b_inv = b ^ {{{w}{{sb}}}};")
    L.append(f"    wire [{w-1}:0] mag_a, mag_b; wire cao, cbo;")
    L.append(f"    cinc{w} ia(.a(a_inv),.add(sa),.y(mag_a),.cout(cao));")
    L.append(f"    cinc{w} ib(.a(b_inv),.add(sb),.y(mag_b),.cout(cbo));")
    L.append(f"    wire [{P-1}:0] umag;")
    L.append(f"    umulcore{w} um(.a(mag_a),.b(mag_b),.product(umag));")
    L.append(f"    wire psign = sa ^ sb;")
    L.append(f"    wire [{P-1}:0] p_inv = umag ^ {{{P}{{psign}}}};")
    L.append(f"    wire [{P-1}:0] pneg; wire pco;")
    L.append(f"    cinc{P} ip(.a(p_inv),.add(psign),.y(pneg),.cout(pco));")
    L.append(f"    assign product = pneg;")
    L.append("endmodule")
    parts=["\n".join(L)+"\n",
           coregen(w, f"umulcore{w}", f"rca{P}"),
           ripple_adder(P, f"rca{P}"),
           cond_inc(w, f"cinc{w}"),
           cond_inc(P, f"cinc{P}"),
           leaf_adders()]
    return "\n".join(parts)

def square_file(w, top):
    """Structural squarer: unsigned array multiply of a by a."""
    P=2*w
    L=[f"module {top}(input [{w-1}:0] a, output [{P-1}:0] product);"]
    L.append(f"    umulcore{w} u(.a(a),.b(a),.product(product));")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+_array_core(w,f"umulcore{w}",f"rca{P}")+"\n"+ripple_adder(P,f"rca{P}")+"\n"+leaf_adders()

if __name__=="__main__":
    print("unsigned array8 lines:", len(unsigned_multiplier_file(8,'mul_array8').splitlines()))
    print("signed wallace8 lines:", len(signed_multiplier_file(8,'mul_x8','csa').splitlines()))


def booth_radix2_file(w, top):
    """
    GENUINE radix-2 Booth multiplier (structural, signed).
    For each bit i, examine (b[i], b[i-1]):
       00,11 -> +0 ; 01 -> +A ; 10 -> -A   (A = multiplicand, sign-extended)
    Accumulate the (conditionally negated) multiplicand shifted left by i,
    using a real ripple-adder accumulation chain. No * operator.
    Booth recoding implemented with explicit encoder logic per step.
    """
    P=2*w
    L=[f"module {top}(input signed [{w-1}:0] a, input signed [{w-1}:0] b, output signed [{P-1}:0] product);"]
    # sign-extend multiplicand a to P bits
    L.append(f"    wire [{P-1}:0] a_ext = {{{{{P-w}{{a[{w-1}]}}}}, a}};")
    L.append(f"    wire [{P-1}:0] a_neg_ext;  wire negc;")
    # -a_ext = ~a_ext + 1  (structural)
    L.append(f"    wire [{P-1}:0] a_inv = ~a_ext;")
    L.append(f"    cinc{P} negm(.a(a_inv),.add(1'b1),.y(a_neg_ext),.cout(negc));")
    # padded multiplier bit b[-1] = 0
    for i in range(w):
        bi=f"b[{i}]"
        bim1 = f"b[{i-1}]" if i>0 else "1'b0"
        # Booth: add = (b[i-1] - b[i]) in {-1,0,+1}
        # selA = (bim1 ^ bi);  // nonzero contribution
        # neg  = bi & ~bim1;   // -1 case
        L.append(f"    wire sel{i} = {bim1} ^ {bi};")
        L.append(f"    wire neg{i} = {bi} & ~{bim1};")
        # operand_i = sel ? (neg ? -A : +A) : 0   then <<i
        L.append(f"    wire [{P-1}:0] base{i} = neg{i} ? a_neg_ext : a_ext;")
        L.append(f"    wire [{P-1}:0] term{i} = sel{i} ? (base{i} << {i}) : {P}'b0;")
    acc="term0"
    for i in range(1,w):
        nxt=f"acc{i}"
        L.append(f"    wire [{P-1}:0] {nxt}; wire co{i};")
        L.append(f"    rca{P} add{i}(.a({acc}),.b(term{i}),.cin(1'b0),.sum({nxt}),.cout(co{i}));")
        acc=nxt
    L.append(f"    assign product = {acc};")
    L.append("endmodule")
    parts=["\n".join(L)+"\n",
           ripple_adder(P,f"rca{P}"),
           cond_inc(P,f"cinc{P}"),
           leaf_adders()]
    return "\n".join(parts)


def restoring_div_file(w, top, signed_wrap=False):
    """
    GENUINE structural restoring divider (combinational, unrolled).
    Computes quotient & remainder of w-bit a / w-bit b with no /,% operator.

    Algorithm (restoring), per step k = w-1 .. 0:
        rem = (rem << 1) | a[k]
        trial = rem - b              (structural subtractor)
        if trial >= 0 (no borrow): rem = trial; q[k]=1
        else                      : rem unchanged; q[k]=0
    Unrolled into w stages of {shift(wiring) + subtractor + mux}.
    Exposes quotient, remainder, divide_by_zero, overflow, valid, busy, done.
    """
    L=[f"module {top}(input [{w-1}:0] a, input [{w-1}:0] b,"]
    L.append(f"    output [{w-1}:0] quotient, output [{w-1}:0] remainder,")
    L.append(f"    output divide_by_zero, output overflow, output valid, output busy, output done);")
    L.append(f"    wire dz = ~(|b);")
    # rem registers as wires per stage; rem has w+1 bits to hold subtract result sign
    L.append(f"    wire [{w}:0] rem0 = {{{w+1}{{1'b0}}}};")
    # We process MSB-first
    prev="rem0"
    for idx in range(w):
        k=w-1-idx
        cur=f"rem{idx+1}"
        sh=f"sh{idx}"
        tr=f"tr{idx}"
        bw=f"bo{idx}"
        # shifted = (prev << 1) | a[k]   -> (w+1) bits
        L.append(f"    wire [{w}:0] {sh} = {{{prev}[{w-1}:0], a[{k}]}};")
        # trial subtract: {sh} - b   (b zero-extended to w+1)
        L.append(f"    wire [{w}:0] {tr}; wire {bw};")
        L.append(f"    subw{w+1}_{idx} sub{idx}(.a({sh}), .b({{1'b0,b}}), .diff({tr}), .bout({bw}));")
        # q bit = ~borrow (sh >= b)
        L.append(f"    wire q{idx} = ~{bw};")
        # rem = q ? trial : shifted
        L.append(f"    wire [{w}:0] {cur} = q{idx} ? {tr} : {sh};")
        prev=cur
    # assemble quotient bits: q0 is for k=w-1 (MSB of quotient)
    qbits=", ".join(f"q{idx}" for idx in range(w))  # q0..q(w-1) -> MSB..LSB
    L.append(f"    assign quotient  = dz ? {{{w}{{1'b1}}}} : {{{qbits}}};")
    L.append(f"    assign remainder = dz ? a : {prev}[{w-1}:0];")
    L.append(f"    assign overflow = 1'b0;")
    L.append(f"    assign valid = ~dz;")
    L.append(f"    assign busy  = 1'b0;")
    L.append(f"    assign done  = 1'b1;")
    L.append("endmodule")
    # emit the (w+1)-bit subtractors (one per stage; unique names) + leaves
    parts=["\n".join(L)+"\n"]
    for idx in range(w):
        parts.append(_subtractor_named(w+1, f"subw{w+1}_{idx}"))
    parts.append(leaf_adders())
    return "\n".join(parts)

def _subtractor_named(w, name):
    """w-bit a-b structural subtractor (a + ~b + 1) reporting borrow=~cout."""
    L=[f"module {name}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] diff, output bout);"]
    L.append(f"    wire [{w}:0] c; assign c[0]=1'b1;")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(~b[{i}]),.cin(c[{i}]),.sum(diff[{i}]),.cout(c[{i+1}]));")
    L.append(f"    assign bout = ~c[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"

def signed_div_file(w, top):
    """Structural signed divider: operate on magnitudes via the unsigned
    restoring array, then fix signs (trunc toward zero, remainder takes
    dividend sign), all structural."""
    L=[f"module {top}(input signed [{w-1}:0] a, input signed [{w-1}:0] b,"]
    L.append(f"    output signed [{w-1}:0] quotient, output signed [{w-1}:0] remainder,")
    L.append(f"    output divide_by_zero, output overflow, output valid, output busy, output done);")
    L.append(f"    wire dz = ~(|b);")
    L.append(f"    wire sa=a[{w-1}], sb=b[{w-1}];")
    L.append(f"    wire [{w-1}:0] mag_a, mag_b; wire ca,cb;")
    L.append(f"    wire [{w-1}:0] ai = a ^ {{{w}{{sa}}}}, bi = b ^ {{{w}{{sb}}}};")
    L.append(f"    cincd{w} na(.a(ai),.add(sa),.y(mag_a),.cout(ca));")
    L.append(f"    cincd{w} nb(.a(bi),.add(sb),.y(mag_b),.cout(cb));")
    L.append(f"    wire [{w-1}:0] uq, ur; wire udz,uov,uv,ub,ud;")
    L.append(f"    udivcore{w} dv(.a(mag_a),.b(mag_b),.quotient(uq),.remainder(ur),")
    L.append(f"        .divide_by_zero(udz),.overflow(uov),.valid(uv),.busy(ub),.done(ud));")
    # quotient sign = sa^sb ; remainder sign = sa
    L.append(f"    wire qs = sa ^ sb;")
    L.append(f"    wire [{w-1}:0] uq_i = uq ^ {{{w}{{qs}}}}; wire [{w-1}:0] q_fixed; wire qc;")
    L.append(f"    cincd{w} fq(.a(uq_i),.add(qs),.y(q_fixed),.cout(qc));")
    L.append(f"    wire [{w-1}:0] ur_i = ur ^ {{{w}{{sa}}}}; wire [{w-1}:0] r_fixed; wire rc;")
    L.append(f"    cincd{w} fr(.a(ur_i),.add(sa),.y(r_fixed),.cout(rc));")
    L.append(f"    assign quotient  = dz ? {{{w}{{1'b1}}}} : q_fixed;")
    L.append(f"    assign remainder = dz ? a : r_fixed;")
    L.append(f"    assign overflow = 1'b0; assign valid=~dz; assign busy=1'b0; assign done=1'b1;")
    L.append("endmodule")
    parts=["\n".join(L)+"\n",
           # unsigned core renamed
           restoring_div_file(w, f"udivcore{w}").replace("","",0),
           cond_inc(w, f"cincd{w}")]
    return "\n".join(parts)


def const_mult_bits(sig, k, outw, prefix):
    """Return (lines, result_wire) computing sig*k structurally via shift-add of
    sig into an outw-bit accumulator. sig is a wire expression (e.g. 'd0' 4-bit).
    Uses only shifts (wiring) and additions are folded by caller. Here we just
    emit the shifted terms; caller sums them. k decomposed into set bits."""
    terms=[]
    lines=[]
    bitpos=[i for i in range(k.bit_length()) if (k>>i)&1]
    for i,bp in enumerate(bitpos):
        w=f"{prefix}_{bp}"
        lines.append(f"    wire [{outw-1}:0] {w} = ({{{outw}'b0}} | {sig}) << {bp};")
        terms.append(w)
    return lines, terms


def restoring_div_nm_file(nw, dw, top):
    """
    Structural restoring divider, independent widths:
      dividend : nw bits   divisor : dw bits
      quotient : nw bits   remainder : dw bits
    Runs nw steps (one per dividend bit, MSB-first), each step a structural
    (dw+1)-bit subtractor + restore mux. No /,% operator.
    """
    rw=dw+1
    L=[f"module {top}(input [{nw-1}:0] dividend, input [{dw-1}:0] divisor,"]
    L.append(f"    output [{nw-1}:0] quotient, output [{dw-1}:0] remainder);")
    L.append(f"    wire [{rw-1}:0] rem0 = {{{rw}{{1'b0}}}};")
    prev="rem0"
    for idx in range(nw):
        k=nw-1-idx
        cur=f"rem{idx+1}"; sh=f"sh{idx}"; tr=f"tr{idx}"; bw=f"bo{idx}"
        L.append(f"    wire [{rw-1}:0] {sh} = {{{prev}[{rw-2}:0], dividend[{k}]}};")
        L.append(f"    wire [{rw-1}:0] {tr}; wire {bw};")
        L.append(f"    fpsub{rw}_{idx} su{idx}(.a({sh}), .b({{1'b0,divisor}}), .diff({tr}), .bout({bw}));")
        L.append(f"    wire q{idx} = ~{bw};")
        L.append(f"    wire [{rw-1}:0] {cur} = q{idx} ? {tr} : {sh};")
        prev=cur
    # q{idx} is quotient bit (nw-1-idx); MSB-first -> concat q0..q(nw-1)
    qbits=", ".join(f"q{idx}" for idx in range(nw))
    L.append(f"    assign quotient  = {{{qbits}}};")
    L.append(f"    assign remainder = {prev}[{dw-1}:0];")
    L.append("endmodule")
    parts=["\n".join(L)+"\n"]
    for idx in range(nw):
        parts.append(_subtractor_named(rw, f"fpsub{rw}_{idx}"))
    parts.append(leaf_adders())
    return "\n".join(parts)


def sqrt_core_file(w, top):
    """
    GENUINE structural integer square root (digit-by-digit, non-restoring),
    combinational unrolled. root = floor(sqrt(a)), rem = a - root^2.
    Each stage: shift in 2 radicand bits, structural subtract of test value,
    select via the borrow. No *, /, % operator.
      input  a    : w bits
      output root : ((w+1)//2) bits
      output rem  : (w//2 + 1) bits
    """
    rw=(w+1)//2          # root bit count
    BW=w+2               # internal bus width (safe)
    L=[f"module {top}(input [{w-1}:0] a, output [{rw-1}:0] root, output [{rw}:0] rem);"]
    # running accumulators as wire chains
    L.append(f"    wire [{BW-1}:0] rem0 = {{{BW}{{1'b0}}}};")
    L.append(f"    wire [{rw-1}:0] root0 = {{{rw}{{1'b0}}}};")
    prem="rem0"; proot="root0"
    for idx in range(rw):
        i=rw-1-idx                    # stage index (high->low)
        sr=f"sr{idx}"; tst=f"ts{idx}"; df=f"df{idx}"; bw_=f"bw{idx}"; ge=f"ge{idx}"
        nrem=f"rem{idx+1}"; nroot=f"root{idx+1}"
        # two radicand bits at position 2*i
        hb=2*i+1; lb=2*i
        hbit = f"a[{hb}]" if hb < w else "1'b0"
        lbit = f"a[{lb}]" if lb < w else "1'b0"
        L.append(f"    wire [{BW-1}:0] {sr} = {{{prem}[{BW-3}:0], {hbit}, {lbit}}};")
        # test = (root << 2) | 1
        L.append(f"    wire [{BW-1}:0] {tst} = {{{proot}, 2'b01}};")
        L.append(f"    wire [{BW-1}:0] {df}; wire {bw_};")
        L.append(f"    sqsub{BW}_{idx} ss{idx}(.a({sr}), .b({tst}), .diff({df}), .bout({bw_}));")
        L.append(f"    wire {ge} = ~{bw_};")
        L.append(f"    wire [{BW-1}:0] {nrem} = {ge} ? {df} : {sr};")
        L.append(f"    wire [{rw-1}:0] {nroot} = {{{proot}[{rw-2}:0], {ge}}};")
        prem=nrem; proot=nroot
    L.append(f"    assign root = {proot};")
    L.append(f"    assign rem  = {prem}[{rw}:0];")
    L.append("endmodule")
    parts=["\n".join(L)+"\n"]
    for idx in range(rw):
        parts.append(_subtractor_named(BW, f"sqsub{BW}_{idx}"))
    parts.append(leaf_adders())
    return "\n".join(parts)


def _strip_leaves(block):
    """Remove a trailing leaf_adders() definition from an assembled block so two
    cores can be concatenated with a single shared leaf definition appended."""
    leaves=leaf_adders()
    idx=block.rfind("module half_adder(")
    if idx!=-1:
        return block[:idx]
    return block
