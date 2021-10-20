
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	dcc78793          	addi	a5,a5,-564 # 80005e30 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	342080e7          	jalr	834(ra) # 80002460 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00001097          	auipc	ra,0x1
    800001ba:	7de080e7          	jalr	2014(ra) # 80001994 <myproc>
    800001be:	551c                	lw	a5,40(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	ea0080e7          	jalr	-352(ra) # 80002066 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	208080e7          	jalr	520(ra) # 8000240a <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	1d2080e7          	jalr	466(ra) # 800024b6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	dba080e7          	jalr	-582(ra) # 800021f2 <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	00021797          	auipc	a5,0x21
    8000046e:	0ae78793          	addi	a5,a5,174 # 80021518 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	960080e7          	jalr	-1696(ra) # 800021f2 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	748080e7          	jalr	1864(ra) # 80002066 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00025797          	auipc	a5,0x25
    80000a02:	60278793          	addi	a5,a5,1538 # 80026000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00025517          	auipc	a0,0x25
    80000ad2:	53250513          	addi	a0,a0,1330 # 80026000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e08080e7          	jalr	-504(ra) # 80001978 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dd6080e7          	jalr	-554(ra) # 80001978 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	dca080e7          	jalr	-566(ra) # 80001978 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	db2080e7          	jalr	-590(ra) # 80001978 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d72080e7          	jalr	-654(ra) # 80001978 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d46080e7          	jalr	-698(ra) # 80001978 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	adc080e7          	jalr	-1316(ra) # 80001968 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	ac0080e7          	jalr	-1344(ra) # 80001968 <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00002097          	auipc	ra,0x2
    80000ece:	9e0080e7          	jalr	-1568(ra) # 800028aa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	f9e080e7          	jalr	-98(ra) # 80005e70 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	fda080e7          	jalr	-38(ra) # 80001eb4 <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	97e080e7          	jalr	-1666(ra) # 800018b8 <procinit>
    trapinit();      // trap vectors
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	940080e7          	jalr	-1728(ra) # 80002882 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	960080e7          	jalr	-1696(ra) # 800028aa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	f08080e7          	jalr	-248(ra) # 80005e5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	f16080e7          	jalr	-234(ra) # 80005e70 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	0ee080e7          	jalr	238(ra) # 80003050 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	77e080e7          	jalr	1918(ra) # 800036e8 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	728080e7          	jalr	1832(ra) # 8000469a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	018080e7          	jalr	24(ra) # 80005f92 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	cf4080e7          	jalr	-780(ra) # 80001c76 <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	5fe080e7          	jalr	1534(ra) # 80001822 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e863          	bltu	a1,s3,800012f6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e5850513          	addi	a0,a0,-424 # 80008128 <digits+0xe8>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	258080e7          	jalr	600(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012e0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012e2:	0532                	slli	a0,a0,0xc
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	706080e7          	jalr	1798(ra) # 800009ea <kfree>
    *pte = 0;
    800012ec:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f0:	995a                	add	s2,s2,s6
    800012f2:	f9397ce3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f6:	4601                	li	a2,0
    800012f8:	85ca                	mv	a1,s2
    800012fa:	8552                	mv	a0,s4
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	cc2080e7          	jalr	-830(ra) # 80000fbe <walk>
    80001304:	84aa                	mv	s1,a0
    80001306:	d54d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001308:	6108                	ld	a0,0(a0)
    8000130a:	00157793          	andi	a5,a0,1
    8000130e:	dbcd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001310:	3ff57793          	andi	a5,a0,1023
    80001314:	fb778ee3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    80001318:	fc0a8ae3          	beqz	s5,800012ec <uvmunmap+0x92>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7be080e7          	jalr	1982(ra) # 80000ae6 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	99a080e7          	jalr	-1638(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	77e080e7          	jalr	1918(ra) # 80000ae6 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	95c080e7          	jalr	-1700(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d1e080e7          	jalr	-738(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	99c080e7          	jalr	-1636(ra) # 80000d32 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d9250513          	addi	a0,a0,-622 # 80008140 <digits+0x100>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	17a080e7          	jalr	378(ra) # 80000530 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6b4080e7          	jalr	1716(ra) # 80000ae6 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	890080e7          	jalr	-1904(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c52080e7          	jalr	-942(ra) # 800010a6 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	55c080e7          	jalr	1372(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c7050513          	addi	a0,a0,-912 # 80008160 <digits+0x120>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	038080e7          	jalr	56(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e8080e7          	jalr	1256(ra) # 800009ea <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a46080e7          	jalr	-1466(ra) # 80000fbe <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	550080e7          	jalr	1360(ra) # 80000ae6 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	78c080e7          	jalr	1932(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	aee080e7          	jalr	-1298(ra) # 800010a6 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	ba450513          	addi	a0,a0,-1116 # 80008170 <digits+0x130>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f5c080e7          	jalr	-164(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bb450513          	addi	a0,a0,-1100 # 80008190 <digits+0x150>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f4c080e7          	jalr	-180(ra) # 80000530 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3fc080e7          	jalr	1020(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	990080e7          	jalr	-1648(ra) # 80000fbe <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b6a50513          	addi	a0,a0,-1174 # 800081b0 <digits+0x170>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	ee2080e7          	jalr	-286(ra) # 80000530 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	6a8080e7          	jalr	1704(ra) # 80000d32 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9bc080e7          	jalr	-1604(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyin+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	412505b3          	sub	a1,a0,s2
    80001714:	8552                	mv	a0,s4
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	61c080e7          	jalr	1564(ra) # 80000d32 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001722:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	930080e7          	jalr	-1744(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyin+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000176e:	c6c5                	beqz	a3,80001816 <copyinstr+0xa8>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	0880                	addi	s0,sp,80
    80001786:	8a2a                	mv	s4,a0
    80001788:	8b2e                	mv	s6,a1
    8000178a:	8bb2                	mv	s7,a2
    8000178c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000178e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001790:	6985                	lui	s3,0x1
    80001792:	a035                	j	800017be <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001794:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001798:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179a:	0017b793          	seqz	a5,a5
    8000179e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017b8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017bc:	c8a9                	beqz	s1,8000180e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017be:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c2:	85ca                	mv	a1,s2
    800017c4:	8552                	mv	a0,s4
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	89e080e7          	jalr	-1890(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017ce:	c131                	beqz	a0,80001812 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d0:	41790833          	sub	a6,s2,s7
    800017d4:	984e                	add	a6,a6,s3
    if(n > max)
    800017d6:	0104f363          	bgeu	s1,a6,800017dc <copyinstr+0x6e>
    800017da:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017dc:	955e                	add	a0,a0,s7
    800017de:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e2:	fc080be3          	beqz	a6,800017b8 <copyinstr+0x4a>
    800017e6:	985a                	add	a6,a6,s6
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	14fd                	addi	s1,s1,-1
    800017f0:	9b26                	add	s6,s6,s1
    800017f2:	00f60733          	add	a4,a2,a5
    800017f6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fa:	df49                	beqz	a4,80001794 <copyinstr+0x26>
        *dst = *p;
    800017fc:	00e78023          	sb	a4,0(a5)
      --max;
    80001800:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001804:	0785                	addi	a5,a5,1
    while(n > 0){
    80001806:	ff0796e3          	bne	a5,a6,800017f2 <copyinstr+0x84>
      dst++;
    8000180a:	8b42                	mv	s6,a6
    8000180c:	b775                	j	800017b8 <copyinstr+0x4a>
    8000180e:	4781                	li	a5,0
    80001810:	b769                	j	8000179a <copyinstr+0x2c>
      return -1;
    80001812:	557d                	li	a0,-1
    80001814:	b779                	j	800017a2 <copyinstr+0x34>
  int got_null = 0;
    80001816:	4781                	li	a5,0
  if(got_null){
    80001818:	0017b793          	seqz	a5,a5
    8000181c:	40f00533          	neg	a0,a5
}
    80001820:	8082                	ret

0000000080001822 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001822:	7139                	addi	sp,sp,-64
    80001824:	fc06                	sd	ra,56(sp)
    80001826:	f822                	sd	s0,48(sp)
    80001828:	f426                	sd	s1,40(sp)
    8000182a:	f04a                	sd	s2,32(sp)
    8000182c:	ec4e                	sd	s3,24(sp)
    8000182e:	e852                	sd	s4,16(sp)
    80001830:	e456                	sd	s5,8(sp)
    80001832:	e05a                	sd	s6,0(sp)
    80001834:	0080                	addi	s0,sp,64
    80001836:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001838:	00010497          	auipc	s1,0x10
    8000183c:	e9848493          	addi	s1,s1,-360 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001840:	8b26                	mv	s6,s1
    80001842:	00006a97          	auipc	s5,0x6
    80001846:	7bea8a93          	addi	s5,s5,1982 # 80008000 <etext>
    8000184a:	04000937          	lui	s2,0x4000
    8000184e:	197d                	addi	s2,s2,-1
    80001850:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001852:	00016a17          	auipc	s4,0x16
    80001856:	a7ea0a13          	addi	s4,s4,-1410 # 800172d0 <tickslock>
    char *pa = kalloc();
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	28c080e7          	jalr	652(ra) # 80000ae6 <kalloc>
    80001862:	862a                	mv	a2,a0
    if(pa == 0)
    80001864:	c131                	beqz	a0,800018a8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001866:	416485b3          	sub	a1,s1,s6
    8000186a:	8591                	srai	a1,a1,0x4
    8000186c:	000ab783          	ld	a5,0(s5)
    80001870:	02f585b3          	mul	a1,a1,a5
    80001874:	2585                	addiw	a1,a1,1
    80001876:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187a:	4719                	li	a4,6
    8000187c:	6685                	lui	a3,0x1
    8000187e:	40b905b3          	sub	a1,s2,a1
    80001882:	854e                	mv	a0,s3
    80001884:	00000097          	auipc	ra,0x0
    80001888:	8b0080e7          	jalr	-1872(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188c:	17048493          	addi	s1,s1,368
    80001890:	fd4495e3          	bne	s1,s4,8000185a <proc_mapstacks+0x38>
  }
}
    80001894:	70e2                	ld	ra,56(sp)
    80001896:	7442                	ld	s0,48(sp)
    80001898:	74a2                	ld	s1,40(sp)
    8000189a:	7902                	ld	s2,32(sp)
    8000189c:	69e2                	ld	s3,24(sp)
    8000189e:	6a42                	ld	s4,16(sp)
    800018a0:	6aa2                	ld	s5,8(sp)
    800018a2:	6b02                	ld	s6,0(sp)
    800018a4:	6121                	addi	sp,sp,64
    800018a6:	8082                	ret
      panic("kalloc");
    800018a8:	00007517          	auipc	a0,0x7
    800018ac:	91850513          	addi	a0,a0,-1768 # 800081c0 <digits+0x180>
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	c80080e7          	jalr	-896(ra) # 80000530 <panic>

00000000800018b8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018b8:	7139                	addi	sp,sp,-64
    800018ba:	fc06                	sd	ra,56(sp)
    800018bc:	f822                	sd	s0,48(sp)
    800018be:	f426                	sd	s1,40(sp)
    800018c0:	f04a                	sd	s2,32(sp)
    800018c2:	ec4e                	sd	s3,24(sp)
    800018c4:	e852                	sd	s4,16(sp)
    800018c6:	e456                	sd	s5,8(sp)
    800018c8:	e05a                	sd	s6,0(sp)
    800018ca:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018cc:	00007597          	auipc	a1,0x7
    800018d0:	8fc58593          	addi	a1,a1,-1796 # 800081c8 <digits+0x188>
    800018d4:	00010517          	auipc	a0,0x10
    800018d8:	9cc50513          	addi	a0,a0,-1588 # 800112a0 <pid_lock>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	26a080e7          	jalr	618(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e4:	00007597          	auipc	a1,0x7
    800018e8:	8ec58593          	addi	a1,a1,-1812 # 800081d0 <digits+0x190>
    800018ec:	00010517          	auipc	a0,0x10
    800018f0:	9cc50513          	addi	a0,a0,-1588 # 800112b8 <wait_lock>
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	252080e7          	jalr	594(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fc:	00010497          	auipc	s1,0x10
    80001900:	dd448493          	addi	s1,s1,-556 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001904:	00007b17          	auipc	s6,0x7
    80001908:	8dcb0b13          	addi	s6,s6,-1828 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    8000190c:	8aa6                	mv	s5,s1
    8000190e:	00006a17          	auipc	s4,0x6
    80001912:	6f2a0a13          	addi	s4,s4,1778 # 80008000 <etext>
    80001916:	04000937          	lui	s2,0x4000
    8000191a:	197d                	addi	s2,s2,-1
    8000191c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191e:	00016997          	auipc	s3,0x16
    80001922:	9b298993          	addi	s3,s3,-1614 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001926:	85da                	mv	a1,s6
    80001928:	8526                	mv	a0,s1
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	21c080e7          	jalr	540(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001932:	415487b3          	sub	a5,s1,s5
    80001936:	8791                	srai	a5,a5,0x4
    80001938:	000a3703          	ld	a4,0(s4)
    8000193c:	02e787b3          	mul	a5,a5,a4
    80001940:	2785                	addiw	a5,a5,1
    80001942:	00d7979b          	slliw	a5,a5,0xd
    80001946:	40f907b3          	sub	a5,s2,a5
    8000194a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	17048493          	addi	s1,s1,368
    80001950:	fd349be3          	bne	s1,s3,80001926 <procinit+0x6e>
  }
}
    80001954:	70e2                	ld	ra,56(sp)
    80001956:	7442                	ld	s0,48(sp)
    80001958:	74a2                	ld	s1,40(sp)
    8000195a:	7902                	ld	s2,32(sp)
    8000195c:	69e2                	ld	s3,24(sp)
    8000195e:	6a42                	ld	s4,16(sp)
    80001960:	6aa2                	ld	s5,8(sp)
    80001962:	6b02                	ld	s6,0(sp)
    80001964:	6121                	addi	sp,sp,64
    80001966:	8082                	ret

0000000080001968 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001968:	1141                	addi	sp,sp,-16
    8000196a:	e422                	sd	s0,8(sp)
    8000196c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000196e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001970:	2501                	sext.w	a0,a0
    80001972:	6422                	ld	s0,8(sp)
    80001974:	0141                	addi	sp,sp,16
    80001976:	8082                	ret

0000000080001978 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001978:	1141                	addi	sp,sp,-16
    8000197a:	e422                	sd	s0,8(sp)
    8000197c:	0800                	addi	s0,sp,16
    8000197e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001980:	2781                	sext.w	a5,a5
    80001982:	079e                	slli	a5,a5,0x7
  return c;
}
    80001984:	00010517          	auipc	a0,0x10
    80001988:	94c50513          	addi	a0,a0,-1716 # 800112d0 <cpus>
    8000198c:	953e                	add	a0,a0,a5
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001994:	1101                	addi	sp,sp,-32
    80001996:	ec06                	sd	ra,24(sp)
    80001998:	e822                	sd	s0,16(sp)
    8000199a:	e426                	sd	s1,8(sp)
    8000199c:	1000                	addi	s0,sp,32
  push_off();
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	1ec080e7          	jalr	492(ra) # 80000b8a <push_off>
    800019a6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019a8:	2781                	sext.w	a5,a5
    800019aa:	079e                	slli	a5,a5,0x7
    800019ac:	00010717          	auipc	a4,0x10
    800019b0:	8f470713          	addi	a4,a4,-1804 # 800112a0 <pid_lock>
    800019b4:	97ba                	add	a5,a5,a4
    800019b6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	272080e7          	jalr	626(ra) # 80000c2a <pop_off>
  return p;
}
    800019c0:	8526                	mv	a0,s1
    800019c2:	60e2                	ld	ra,24(sp)
    800019c4:	6442                	ld	s0,16(sp)
    800019c6:	64a2                	ld	s1,8(sp)
    800019c8:	6105                	addi	sp,sp,32
    800019ca:	8082                	ret

00000000800019cc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e406                	sd	ra,8(sp)
    800019d0:	e022                	sd	s0,0(sp)
    800019d2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	fc0080e7          	jalr	-64(ra) # 80001994 <myproc>
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	2ae080e7          	jalr	686(ra) # 80000c8a <release>

  if (first) {
    800019e4:	00007797          	auipc	a5,0x7
    800019e8:	e2c7a783          	lw	a5,-468(a5) # 80008810 <first.1678>
    800019ec:	eb89                	bnez	a5,800019fe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ee:	00001097          	auipc	ra,0x1
    800019f2:	ed4080e7          	jalr	-300(ra) # 800028c2 <usertrapret>
}
    800019f6:	60a2                	ld	ra,8(sp)
    800019f8:	6402                	ld	s0,0(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret
    first = 0;
    800019fe:	00007797          	auipc	a5,0x7
    80001a02:	e007a923          	sw	zero,-494(a5) # 80008810 <first.1678>
    fsinit(ROOTDEV);
    80001a06:	4505                	li	a0,1
    80001a08:	00002097          	auipc	ra,0x2
    80001a0c:	c60080e7          	jalr	-928(ra) # 80003668 <fsinit>
    80001a10:	bff9                	j	800019ee <forkret+0x22>

0000000080001a12 <allocpid>:
allocpid() {
    80001a12:	1101                	addi	sp,sp,-32
    80001a14:	ec06                	sd	ra,24(sp)
    80001a16:	e822                	sd	s0,16(sp)
    80001a18:	e426                	sd	s1,8(sp)
    80001a1a:	e04a                	sd	s2,0(sp)
    80001a1c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a1e:	00010917          	auipc	s2,0x10
    80001a22:	88290913          	addi	s2,s2,-1918 # 800112a0 <pid_lock>
    80001a26:	854a                	mv	a0,s2
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	de478793          	addi	a5,a5,-540 # 80008814 <nextpid>
    80001a38:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3a:	0014871b          	addiw	a4,s1,1
    80001a3e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a40:	854a                	mv	a0,s2
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	248080e7          	jalr	584(ra) # 80000c8a <release>
}
    80001a4a:	8526                	mv	a0,s1
    80001a4c:	60e2                	ld	ra,24(sp)
    80001a4e:	6442                	ld	s0,16(sp)
    80001a50:	64a2                	ld	s1,8(sp)
    80001a52:	6902                	ld	s2,0(sp)
    80001a54:	6105                	addi	sp,sp,32
    80001a56:	8082                	ret

0000000080001a58 <proc_pagetable>:
{
    80001a58:	1101                	addi	sp,sp,-32
    80001a5a:	ec06                	sd	ra,24(sp)
    80001a5c:	e822                	sd	s0,16(sp)
    80001a5e:	e426                	sd	s1,8(sp)
    80001a60:	e04a                	sd	s2,0(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	8b8080e7          	jalr	-1864(ra) # 8000131e <uvmcreate>
    80001a6e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a70:	c121                	beqz	a0,80001ab0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a72:	4729                	li	a4,10
    80001a74:	00005697          	auipc	a3,0x5
    80001a78:	58c68693          	addi	a3,a3,1420 # 80007000 <_trampoline>
    80001a7c:	6605                	lui	a2,0x1
    80001a7e:	040005b7          	lui	a1,0x4000
    80001a82:	15fd                	addi	a1,a1,-1
    80001a84:	05b2                	slli	a1,a1,0xc
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	620080e7          	jalr	1568(ra) # 800010a6 <mappages>
    80001a8e:	02054863          	bltz	a0,80001abe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a92:	4719                	li	a4,6
    80001a94:	05893683          	ld	a3,88(s2)
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	020005b7          	lui	a1,0x2000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b6                	slli	a1,a1,0xd
    80001aa2:	8526                	mv	a0,s1
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	602080e7          	jalr	1538(ra) # 800010a6 <mappages>
    80001aac:	02054163          	bltz	a0,80001ace <proc_pagetable+0x76>
}
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	60e2                	ld	ra,24(sp)
    80001ab4:	6442                	ld	s0,16(sp)
    80001ab6:	64a2                	ld	s1,8(sp)
    80001ab8:	6902                	ld	s2,0(sp)
    80001aba:	6105                	addi	sp,sp,32
    80001abc:	8082                	ret
    uvmfree(pagetable, 0);
    80001abe:	4581                	li	a1,0
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	00000097          	auipc	ra,0x0
    80001ac6:	a58080e7          	jalr	-1448(ra) # 8000151a <uvmfree>
    return 0;
    80001aca:	4481                	li	s1,0
    80001acc:	b7d5                	j	80001ab0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ace:	4681                	li	a3,0
    80001ad0:	4605                	li	a2,1
    80001ad2:	040005b7          	lui	a1,0x4000
    80001ad6:	15fd                	addi	a1,a1,-1
    80001ad8:	05b2                	slli	a1,a1,0xc
    80001ada:	8526                	mv	a0,s1
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	77e080e7          	jalr	1918(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae4:	4581                	li	a1,0
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	a32080e7          	jalr	-1486(ra) # 8000151a <uvmfree>
    return 0;
    80001af0:	4481                	li	s1,0
    80001af2:	bf7d                	j	80001ab0 <proc_pagetable+0x58>

0000000080001af4 <proc_freepagetable>:
{
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
    80001b00:	84aa                	mv	s1,a0
    80001b02:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b04:	4681                	li	a3,0
    80001b06:	4605                	li	a2,1
    80001b08:	040005b7          	lui	a1,0x4000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b2                	slli	a1,a1,0xc
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	74a080e7          	jalr	1866(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b18:	4681                	li	a3,0
    80001b1a:	4605                	li	a2,1
    80001b1c:	020005b7          	lui	a1,0x2000
    80001b20:	15fd                	addi	a1,a1,-1
    80001b22:	05b6                	slli	a1,a1,0xd
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	734080e7          	jalr	1844(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b2e:	85ca                	mv	a1,s2
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	9e8080e7          	jalr	-1560(ra) # 8000151a <uvmfree>
}
    80001b3a:	60e2                	ld	ra,24(sp)
    80001b3c:	6442                	ld	s0,16(sp)
    80001b3e:	64a2                	ld	s1,8(sp)
    80001b40:	6902                	ld	s2,0(sp)
    80001b42:	6105                	addi	sp,sp,32
    80001b44:	8082                	ret

0000000080001b46 <freeproc>:
{
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	e426                	sd	s1,8(sp)
    80001b4e:	1000                	addi	s0,sp,32
    80001b50:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b52:	6d28                	ld	a0,88(a0)
    80001b54:	c509                	beqz	a0,80001b5e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	e94080e7          	jalr	-364(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b5e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b62:	68a8                	ld	a0,80(s1)
    80001b64:	c511                	beqz	a0,80001b70 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b66:	64ac                	ld	a1,72(s1)
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	f8c080e7          	jalr	-116(ra) # 80001af4 <proc_freepagetable>
  p->pagetable = 0;
    80001b70:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b74:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b78:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b80:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b84:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b88:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b90:	0004ac23          	sw	zero,24(s1)
}
    80001b94:	60e2                	ld	ra,24(sp)
    80001b96:	6442                	ld	s0,16(sp)
    80001b98:	64a2                	ld	s1,8(sp)
    80001b9a:	6105                	addi	sp,sp,32
    80001b9c:	8082                	ret

0000000080001b9e <allocproc>:
{
    80001b9e:	7179                	addi	sp,sp,-48
    80001ba0:	f406                	sd	ra,40(sp)
    80001ba2:	f022                	sd	s0,32(sp)
    80001ba4:	ec26                	sd	s1,24(sp)
    80001ba6:	e84a                	sd	s2,16(sp)
    80001ba8:	e44e                	sd	s3,8(sp)
    80001baa:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    p->priority = 10;
    80001bb4:	4929                	li	s2,10
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb6:	00015997          	auipc	s3,0x15
    80001bba:	71a98993          	addi	s3,s3,1818 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	016080e7          	jalr	22(ra) # 80000bd6 <acquire>
    p->priority = 10;
    80001bc8:	1724b423          	sd	s2,360(s1)
    if(p->state == UNUSED) {
    80001bcc:	4c9c                	lw	a5,24(s1)
    80001bce:	cf81                	beqz	a5,80001be6 <allocproc+0x48>
      release(&p->lock);
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	0b8080e7          	jalr	184(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bda:	17048493          	addi	s1,s1,368
    80001bde:	ff3490e3          	bne	s1,s3,80001bbe <allocproc+0x20>
  return 0;
    80001be2:	4481                	li	s1,0
    80001be4:	a889                	j	80001c36 <allocproc+0x98>
  p->pid = allocpid();
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	e2c080e7          	jalr	-468(ra) # 80001a12 <allocpid>
    80001bee:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bf0:	4785                	li	a5,1
    80001bf2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	ef2080e7          	jalr	-270(ra) # 80000ae6 <kalloc>
    80001bfc:	892a                	mv	s2,a0
    80001bfe:	eca8                	sd	a0,88(s1)
    80001c00:	c139                	beqz	a0,80001c46 <allocproc+0xa8>
  p->pagetable = proc_pagetable(p);
    80001c02:	8526                	mv	a0,s1
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	e54080e7          	jalr	-428(ra) # 80001a58 <proc_pagetable>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c10:	c539                	beqz	a0,80001c5e <allocproc+0xc0>
  memset(&p->context, 0, sizeof(p->context));
    80001c12:	07000613          	li	a2,112
    80001c16:	4581                	li	a1,0
    80001c18:	06048513          	addi	a0,s1,96
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	0b6080e7          	jalr	182(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c24:	00000797          	auipc	a5,0x0
    80001c28:	da878793          	addi	a5,a5,-600 # 800019cc <forkret>
    80001c2c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c2e:	60bc                	ld	a5,64(s1)
    80001c30:	6705                	lui	a4,0x1
    80001c32:	97ba                	add	a5,a5,a4
    80001c34:	f4bc                	sd	a5,104(s1)
}
    80001c36:	8526                	mv	a0,s1
    80001c38:	70a2                	ld	ra,40(sp)
    80001c3a:	7402                	ld	s0,32(sp)
    80001c3c:	64e2                	ld	s1,24(sp)
    80001c3e:	6942                	ld	s2,16(sp)
    80001c40:	69a2                	ld	s3,8(sp)
    80001c42:	6145                	addi	sp,sp,48
    80001c44:	8082                	ret
    freeproc(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	efe080e7          	jalr	-258(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	038080e7          	jalr	56(ra) # 80000c8a <release>
    return 0;
    80001c5a:	84ca                	mv	s1,s2
    80001c5c:	bfe9                	j	80001c36 <allocproc+0x98>
    freeproc(p);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	ee6080e7          	jalr	-282(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
    return 0;
    80001c72:	84ca                	mv	s1,s2
    80001c74:	b7c9                	j	80001c36 <allocproc+0x98>

0000000080001c76 <userinit>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	f1e080e7          	jalr	-226(ra) # 80001b9e <allocproc>
    80001c88:	84aa                	mv	s1,a0
  initproc = p;
    80001c8a:	00007797          	auipc	a5,0x7
    80001c8e:	38a7bf23          	sd	a0,926(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c92:	03400613          	li	a2,52
    80001c96:	00007597          	auipc	a1,0x7
    80001c9a:	b8a58593          	addi	a1,a1,-1142 # 80008820 <initcode>
    80001c9e:	6928                	ld	a0,80(a0)
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	6ac080e7          	jalr	1708(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca8:	6785                	lui	a5,0x1
    80001caa:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cac:	6cb8                	ld	a4,88(s1)
    80001cae:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb2:	6cb8                	ld	a4,88(s1)
    80001cb4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cb6:	4641                	li	a2,16
    80001cb8:	00006597          	auipc	a1,0x6
    80001cbc:	53058593          	addi	a1,a1,1328 # 800081e8 <digits+0x1a8>
    80001cc0:	15848513          	addi	a0,s1,344
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	164080e7          	jalr	356(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001ccc:	00006517          	auipc	a0,0x6
    80001cd0:	52c50513          	addi	a0,a0,1324 # 800081f8 <digits+0x1b8>
    80001cd4:	00002097          	auipc	ra,0x2
    80001cd8:	3c2080e7          	jalr	962(ra) # 80004096 <namei>
    80001cdc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce0:	478d                	li	a5,3
    80001ce2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	fa4080e7          	jalr	-92(ra) # 80000c8a <release>
}
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret

0000000080001cf8 <growproc>:
{
    80001cf8:	1101                	addi	sp,sp,-32
    80001cfa:	ec06                	sd	ra,24(sp)
    80001cfc:	e822                	sd	s0,16(sp)
    80001cfe:	e426                	sd	s1,8(sp)
    80001d00:	e04a                	sd	s2,0(sp)
    80001d02:	1000                	addi	s0,sp,32
    80001d04:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	c8e080e7          	jalr	-882(ra) # 80001994 <myproc>
    80001d0e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d10:	652c                	ld	a1,72(a0)
    80001d12:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d16:	00904f63          	bgtz	s1,80001d34 <growproc+0x3c>
  } else if(n < 0){
    80001d1a:	0204cc63          	bltz	s1,80001d52 <growproc+0x5a>
  p->sz = sz;
    80001d1e:	1602                	slli	a2,a2,0x20
    80001d20:	9201                	srli	a2,a2,0x20
    80001d22:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d26:	4501                	li	a0,0
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6902                	ld	s2,0(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d34:	9e25                	addw	a2,a2,s1
    80001d36:	1602                	slli	a2,a2,0x20
    80001d38:	9201                	srli	a2,a2,0x20
    80001d3a:	1582                	slli	a1,a1,0x20
    80001d3c:	9181                	srli	a1,a1,0x20
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6c6080e7          	jalr	1734(ra) # 80001406 <uvmalloc>
    80001d48:	0005061b          	sext.w	a2,a0
    80001d4c:	fa69                	bnez	a2,80001d1e <growproc+0x26>
      return -1;
    80001d4e:	557d                	li	a0,-1
    80001d50:	bfe1                	j	80001d28 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d52:	9e25                	addw	a2,a2,s1
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	1582                	slli	a1,a1,0x20
    80001d5a:	9181                	srli	a1,a1,0x20
    80001d5c:	6928                	ld	a0,80(a0)
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	660080e7          	jalr	1632(ra) # 800013be <uvmdealloc>
    80001d66:	0005061b          	sext.w	a2,a0
    80001d6a:	bf55                	j	80001d1e <growproc+0x26>

0000000080001d6c <fork>:
{
    80001d6c:	7179                	addi	sp,sp,-48
    80001d6e:	f406                	sd	ra,40(sp)
    80001d70:	f022                	sd	s0,32(sp)
    80001d72:	ec26                	sd	s1,24(sp)
    80001d74:	e84a                	sd	s2,16(sp)
    80001d76:	e44e                	sd	s3,8(sp)
    80001d78:	e052                	sd	s4,0(sp)
    80001d7a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	c18080e7          	jalr	-1000(ra) # 80001994 <myproc>
    80001d84:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	e18080e7          	jalr	-488(ra) # 80001b9e <allocproc>
    80001d8e:	12050163          	beqz	a0,80001eb0 <fork+0x144>
    80001d92:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d94:	04893603          	ld	a2,72(s2)
    80001d98:	692c                	ld	a1,80(a0)
    80001d9a:	05093503          	ld	a0,80(s2)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	7b4080e7          	jalr	1972(ra) # 80001552 <uvmcopy>
    80001da6:	04054c63          	bltz	a0,80001dfe <fork+0x92>
  np->sz = p->sz;
    80001daa:	04893783          	ld	a5,72(s2)
    80001dae:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001db2:	05893683          	ld	a3,88(s2)
    80001db6:	87b6                	mv	a5,a3
    80001db8:	0589b703          	ld	a4,88(s3)
    80001dbc:	12068693          	addi	a3,a3,288
    80001dc0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc4:	6788                	ld	a0,8(a5)
    80001dc6:	6b8c                	ld	a1,16(a5)
    80001dc8:	6f90                	ld	a2,24(a5)
    80001dca:	01073023          	sd	a6,0(a4)
    80001dce:	e708                	sd	a0,8(a4)
    80001dd0:	eb0c                	sd	a1,16(a4)
    80001dd2:	ef10                	sd	a2,24(a4)
    80001dd4:	02078793          	addi	a5,a5,32
    80001dd8:	02070713          	addi	a4,a4,32
    80001ddc:	fed792e3          	bne	a5,a3,80001dc0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001de0:	0589b783          	ld	a5,88(s3)
    80001de4:	0607b823          	sd	zero,112(a5)
  if(p->priority != 0) {
    80001de8:	16893783          	ld	a5,360(s2)
    80001dec:	c781                	beqz	a5,80001df4 <fork+0x88>
    np->priority = p->priority - 2;
    80001dee:	17f9                	addi	a5,a5,-2
    80001df0:	16f9b423          	sd	a5,360(s3)
{
    80001df4:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001df8:	15000a13          	li	s4,336
    80001dfc:	a03d                	j	80001e2a <fork+0xbe>
    freeproc(np);
    80001dfe:	854e                	mv	a0,s3
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	d46080e7          	jalr	-698(ra) # 80001b46 <freeproc>
    release(&np->lock);
    80001e08:	854e                	mv	a0,s3
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	e80080e7          	jalr	-384(ra) # 80000c8a <release>
    return -1;
    80001e12:	5a7d                	li	s4,-1
    80001e14:	a069                	j	80001e9e <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e16:	00003097          	auipc	ra,0x3
    80001e1a:	916080e7          	jalr	-1770(ra) # 8000472c <filedup>
    80001e1e:	009987b3          	add	a5,s3,s1
    80001e22:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e24:	04a1                	addi	s1,s1,8
    80001e26:	01448763          	beq	s1,s4,80001e34 <fork+0xc8>
    if(p->ofile[i])
    80001e2a:	009907b3          	add	a5,s2,s1
    80001e2e:	6388                	ld	a0,0(a5)
    80001e30:	f17d                	bnez	a0,80001e16 <fork+0xaa>
    80001e32:	bfcd                	j	80001e24 <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e34:	15093503          	ld	a0,336(s2)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	a6a080e7          	jalr	-1430(ra) # 800038a2 <idup>
    80001e40:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	15890593          	addi	a1,s2,344
    80001e4a:	15898513          	addi	a0,s3,344
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fda080e7          	jalr	-38(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e56:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e5a:	854e                	mv	a0,s3
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	45448493          	addi	s1,s1,1108 # 800112b8 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d68080e7          	jalr	-664(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e76:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e84:	854e                	mv	a0,s3
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d50080e7          	jalr	-688(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
}
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	70a2                	ld	ra,40(sp)
    80001ea2:	7402                	ld	s0,32(sp)
    80001ea4:	64e2                	ld	s1,24(sp)
    80001ea6:	6942                	ld	s2,16(sp)
    80001ea8:	69a2                	ld	s3,8(sp)
    80001eaa:	6a02                	ld	s4,0(sp)
    80001eac:	6145                	addi	sp,sp,48
    80001eae:	8082                	ret
    return -1;
    80001eb0:	5a7d                	li	s4,-1
    80001eb2:	b7f5                	j	80001e9e <fork+0x132>

0000000080001eb4 <scheduler>:
{
    80001eb4:	7139                	addi	sp,sp,-64
    80001eb6:	fc06                	sd	ra,56(sp)
    80001eb8:	f822                	sd	s0,48(sp)
    80001eba:	f426                	sd	s1,40(sp)
    80001ebc:	f04a                	sd	s2,32(sp)
    80001ebe:	ec4e                	sd	s3,24(sp)
    80001ec0:	e852                	sd	s4,16(sp)
    80001ec2:	e456                	sd	s5,8(sp)
    80001ec4:	e05a                	sd	s6,0(sp)
    80001ec6:	0080                	addi	s0,sp,64
    80001ec8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eca:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ecc:	00779a93          	slli	s5,a5,0x7
    80001ed0:	0000f717          	auipc	a4,0xf
    80001ed4:	3d070713          	addi	a4,a4,976 # 800112a0 <pid_lock>
    80001ed8:	9756                	add	a4,a4,s5
    80001eda:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ede:	0000f717          	auipc	a4,0xf
    80001ee2:	3fa70713          	addi	a4,a4,1018 # 800112d8 <cpus+0x8>
    80001ee6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ee8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eea:	4b11                	li	s6,4
        c->proc = p;
    80001eec:	079e                	slli	a5,a5,0x7
    80001eee:	0000fa17          	auipc	s4,0xf
    80001ef2:	3b2a0a13          	addi	s4,s4,946 # 800112a0 <pid_lock>
    80001ef6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef8:	00015917          	auipc	s2,0x15
    80001efc:	3d890913          	addi	s2,s2,984 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f00:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f04:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f08:	10079073          	csrw	sstatus,a5
    80001f0c:	0000f497          	auipc	s1,0xf
    80001f10:	7c448493          	addi	s1,s1,1988 # 800116d0 <proc>
    80001f14:	a03d                	j	80001f42 <scheduler+0x8e>
        p->state = RUNNING;
    80001f16:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f1e:	06048593          	addi	a1,s1,96
    80001f22:	8556                	mv	a0,s5
    80001f24:	00001097          	auipc	ra,0x1
    80001f28:	8f4080e7          	jalr	-1804(ra) # 80002818 <swtch>
        c->proc = 0;
    80001f2c:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f30:	8526                	mv	a0,s1
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	d58080e7          	jalr	-680(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3a:	17048493          	addi	s1,s1,368
    80001f3e:	fd2481e3          	beq	s1,s2,80001f00 <scheduler+0x4c>
      acquire(&p->lock);
    80001f42:	8526                	mv	a0,s1
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	c92080e7          	jalr	-878(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f4c:	4c9c                	lw	a5,24(s1)
    80001f4e:	ff3791e3          	bne	a5,s3,80001f30 <scheduler+0x7c>
    80001f52:	b7d1                	j	80001f16 <scheduler+0x62>

0000000080001f54 <sched>:
{
    80001f54:	7179                	addi	sp,sp,-48
    80001f56:	f406                	sd	ra,40(sp)
    80001f58:	f022                	sd	s0,32(sp)
    80001f5a:	ec26                	sd	s1,24(sp)
    80001f5c:	e84a                	sd	s2,16(sp)
    80001f5e:	e44e                	sd	s3,8(sp)
    80001f60:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	a32080e7          	jalr	-1486(ra) # 80001994 <myproc>
    80001f6a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	bf0080e7          	jalr	-1040(ra) # 80000b5c <holding>
    80001f74:	c93d                	beqz	a0,80001fea <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f76:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f78:	2781                	sext.w	a5,a5
    80001f7a:	079e                	slli	a5,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	32470713          	addi	a4,a4,804 # 800112a0 <pid_lock>
    80001f84:	97ba                	add	a5,a5,a4
    80001f86:	0a87a703          	lw	a4,168(a5)
    80001f8a:	4785                	li	a5,1
    80001f8c:	06f71763          	bne	a4,a5,80001ffa <sched+0xa6>
  if(p->state == RUNNING)
    80001f90:	4c98                	lw	a4,24(s1)
    80001f92:	4791                	li	a5,4
    80001f94:	06f70b63          	beq	a4,a5,8000200a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f9e:	efb5                	bnez	a5,8000201a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa2:	0000f917          	auipc	s2,0xf
    80001fa6:	2fe90913          	addi	s2,s2,766 # 800112a0 <pid_lock>
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	97ca                	add	a5,a5,s2
    80001fb0:	0ac7a983          	lw	s3,172(a5)
    80001fb4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	0000f597          	auipc	a1,0xf
    80001fbe:	31e58593          	addi	a1,a1,798 # 800112d8 <cpus+0x8>
    80001fc2:	95be                	add	a1,a1,a5
    80001fc4:	06048513          	addi	a0,s1,96
    80001fc8:	00001097          	auipc	ra,0x1
    80001fcc:	850080e7          	jalr	-1968(ra) # 80002818 <swtch>
    80001fd0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd2:	2781                	sext.w	a5,a5
    80001fd4:	079e                	slli	a5,a5,0x7
    80001fd6:	97ca                	add	a5,a5,s2
    80001fd8:	0b37a623          	sw	s3,172(a5)
}
    80001fdc:	70a2                	ld	ra,40(sp)
    80001fde:	7402                	ld	s0,32(sp)
    80001fe0:	64e2                	ld	s1,24(sp)
    80001fe2:	6942                	ld	s2,16(sp)
    80001fe4:	69a2                	ld	s3,8(sp)
    80001fe6:	6145                	addi	sp,sp,48
    80001fe8:	8082                	ret
    panic("sched p->lock");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	21650513          	addi	a0,a0,534 # 80008200 <digits+0x1c0>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	53e080e7          	jalr	1342(ra) # 80000530 <panic>
    panic("sched locks");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	21650513          	addi	a0,a0,534 # 80008210 <digits+0x1d0>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	52e080e7          	jalr	1326(ra) # 80000530 <panic>
    panic("sched running");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	21650513          	addi	a0,a0,534 # 80008220 <digits+0x1e0>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	51e080e7          	jalr	1310(ra) # 80000530 <panic>
    panic("sched interruptible");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	21650513          	addi	a0,a0,534 # 80008230 <digits+0x1f0>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	50e080e7          	jalr	1294(ra) # 80000530 <panic>

000000008000202a <yield>:
{
    8000202a:	1101                	addi	sp,sp,-32
    8000202c:	ec06                	sd	ra,24(sp)
    8000202e:	e822                	sd	s0,16(sp)
    80002030:	e426                	sd	s1,8(sp)
    80002032:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002034:	00000097          	auipc	ra,0x0
    80002038:	960080e7          	jalr	-1696(ra) # 80001994 <myproc>
    8000203c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	b98080e7          	jalr	-1128(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002046:	478d                	li	a5,3
    80002048:	cc9c                	sw	a5,24(s1)
  sched();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	f0a080e7          	jalr	-246(ra) # 80001f54 <sched>
  release(&p->lock);
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c36080e7          	jalr	-970(ra) # 80000c8a <release>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6105                	addi	sp,sp,32
    80002064:	8082                	ret

0000000080002066 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002066:	7179                	addi	sp,sp,-48
    80002068:	f406                	sd	ra,40(sp)
    8000206a:	f022                	sd	s0,32(sp)
    8000206c:	ec26                	sd	s1,24(sp)
    8000206e:	e84a                	sd	s2,16(sp)
    80002070:	e44e                	sd	s3,8(sp)
    80002072:	1800                	addi	s0,sp,48
    80002074:	89aa                	mv	s3,a0
    80002076:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	91c080e7          	jalr	-1764(ra) # 80001994 <myproc>
    80002080:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	b54080e7          	jalr	-1196(ra) # 80000bd6 <acquire>
  release(lk);
    8000208a:	854a                	mv	a0,s2
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	bfe080e7          	jalr	-1026(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002094:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002098:	4789                	li	a5,2
    8000209a:	cc9c                	sw	a5,24(s1)

  sched();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	eb8080e7          	jalr	-328(ra) # 80001f54 <sched>

  // Tidy up.
  p->chan = 0;
    800020a4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	be0080e7          	jalr	-1056(ra) # 80000c8a <release>
  acquire(lk);
    800020b2:	854a                	mv	a0,s2
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	b22080e7          	jalr	-1246(ra) # 80000bd6 <acquire>
}
    800020bc:	70a2                	ld	ra,40(sp)
    800020be:	7402                	ld	s0,32(sp)
    800020c0:	64e2                	ld	s1,24(sp)
    800020c2:	6942                	ld	s2,16(sp)
    800020c4:	69a2                	ld	s3,8(sp)
    800020c6:	6145                	addi	sp,sp,48
    800020c8:	8082                	ret

00000000800020ca <wait>:
{
    800020ca:	715d                	addi	sp,sp,-80
    800020cc:	e486                	sd	ra,72(sp)
    800020ce:	e0a2                	sd	s0,64(sp)
    800020d0:	fc26                	sd	s1,56(sp)
    800020d2:	f84a                	sd	s2,48(sp)
    800020d4:	f44e                	sd	s3,40(sp)
    800020d6:	f052                	sd	s4,32(sp)
    800020d8:	ec56                	sd	s5,24(sp)
    800020da:	e85a                	sd	s6,16(sp)
    800020dc:	e45e                	sd	s7,8(sp)
    800020de:	e062                	sd	s8,0(sp)
    800020e0:	0880                	addi	s0,sp,80
    800020e2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	8b0080e7          	jalr	-1872(ra) # 80001994 <myproc>
    800020ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020ee:	0000f517          	auipc	a0,0xf
    800020f2:	1ca50513          	addi	a0,a0,458 # 800112b8 <wait_lock>
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	ae0080e7          	jalr	-1312(ra) # 80000bd6 <acquire>
    havekids = 0;
    800020fe:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002100:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002102:	00015997          	auipc	s3,0x15
    80002106:	1ce98993          	addi	s3,s3,462 # 800172d0 <tickslock>
        havekids = 1;
    8000210a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000210c:	0000fc17          	auipc	s8,0xf
    80002110:	1acc0c13          	addi	s8,s8,428 # 800112b8 <wait_lock>
    havekids = 0;
    80002114:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002116:	0000f497          	auipc	s1,0xf
    8000211a:	5ba48493          	addi	s1,s1,1466 # 800116d0 <proc>
    8000211e:	a0bd                	j	8000218c <wait+0xc2>
          pid = np->pid;
    80002120:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002124:	000b0e63          	beqz	s6,80002140 <wait+0x76>
    80002128:	4691                	li	a3,4
    8000212a:	02c48613          	addi	a2,s1,44
    8000212e:	85da                	mv	a1,s6
    80002130:	05093503          	ld	a0,80(s2)
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	522080e7          	jalr	1314(ra) # 80001656 <copyout>
    8000213c:	02054563          	bltz	a0,80002166 <wait+0x9c>
          freeproc(np);
    80002140:	8526                	mv	a0,s1
    80002142:	00000097          	auipc	ra,0x0
    80002146:	a04080e7          	jalr	-1532(ra) # 80001b46 <freeproc>
          release(&np->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b3e080e7          	jalr	-1218(ra) # 80000c8a <release>
          release(&wait_lock);
    80002154:	0000f517          	auipc	a0,0xf
    80002158:	16450513          	addi	a0,a0,356 # 800112b8 <wait_lock>
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
          return pid;
    80002164:	a09d                	j	800021ca <wait+0x100>
            release(&np->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b22080e7          	jalr	-1246(ra) # 80000c8a <release>
            release(&wait_lock);
    80002170:	0000f517          	auipc	a0,0xf
    80002174:	14850513          	addi	a0,a0,328 # 800112b8 <wait_lock>
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b12080e7          	jalr	-1262(ra) # 80000c8a <release>
            return -1;
    80002180:	59fd                	li	s3,-1
    80002182:	a0a1                	j	800021ca <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002184:	17048493          	addi	s1,s1,368
    80002188:	03348463          	beq	s1,s3,800021b0 <wait+0xe6>
      if(np->parent == p){
    8000218c:	7c9c                	ld	a5,56(s1)
    8000218e:	ff279be3          	bne	a5,s2,80002184 <wait+0xba>
        acquire(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	a42080e7          	jalr	-1470(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    8000219c:	4c9c                	lw	a5,24(s1)
    8000219e:	f94781e3          	beq	a5,s4,80002120 <wait+0x56>
        release(&np->lock);
    800021a2:	8526                	mv	a0,s1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	ae6080e7          	jalr	-1306(ra) # 80000c8a <release>
        havekids = 1;
    800021ac:	8756                	mv	a4,s5
    800021ae:	bfd9                	j	80002184 <wait+0xba>
    if(!havekids || p->killed){
    800021b0:	c701                	beqz	a4,800021b8 <wait+0xee>
    800021b2:	02892783          	lw	a5,40(s2)
    800021b6:	c79d                	beqz	a5,800021e4 <wait+0x11a>
      release(&wait_lock);
    800021b8:	0000f517          	auipc	a0,0xf
    800021bc:	10050513          	addi	a0,a0,256 # 800112b8 <wait_lock>
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	aca080e7          	jalr	-1334(ra) # 80000c8a <release>
      return -1;
    800021c8:	59fd                	li	s3,-1
}
    800021ca:	854e                	mv	a0,s3
    800021cc:	60a6                	ld	ra,72(sp)
    800021ce:	6406                	ld	s0,64(sp)
    800021d0:	74e2                	ld	s1,56(sp)
    800021d2:	7942                	ld	s2,48(sp)
    800021d4:	79a2                	ld	s3,40(sp)
    800021d6:	7a02                	ld	s4,32(sp)
    800021d8:	6ae2                	ld	s5,24(sp)
    800021da:	6b42                	ld	s6,16(sp)
    800021dc:	6ba2                	ld	s7,8(sp)
    800021de:	6c02                	ld	s8,0(sp)
    800021e0:	6161                	addi	sp,sp,80
    800021e2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021e4:	85e2                	mv	a1,s8
    800021e6:	854a                	mv	a0,s2
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	e7e080e7          	jalr	-386(ra) # 80002066 <sleep>
    havekids = 0;
    800021f0:	b715                	j	80002114 <wait+0x4a>

00000000800021f2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021f2:	7139                	addi	sp,sp,-64
    800021f4:	fc06                	sd	ra,56(sp)
    800021f6:	f822                	sd	s0,48(sp)
    800021f8:	f426                	sd	s1,40(sp)
    800021fa:	f04a                	sd	s2,32(sp)
    800021fc:	ec4e                	sd	s3,24(sp)
    800021fe:	e852                	sd	s4,16(sp)
    80002200:	e456                	sd	s5,8(sp)
    80002202:	0080                	addi	s0,sp,64
    80002204:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	0000f497          	auipc	s1,0xf
    8000220a:	4ca48493          	addi	s1,s1,1226 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000220e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002210:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002212:	00015917          	auipc	s2,0x15
    80002216:	0be90913          	addi	s2,s2,190 # 800172d0 <tickslock>
    8000221a:	a821                	j	80002232 <wakeup+0x40>
        p->state = RUNNABLE;
    8000221c:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a68080e7          	jalr	-1432(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000222a:	17048493          	addi	s1,s1,368
    8000222e:	03248463          	beq	s1,s2,80002256 <wakeup+0x64>
    if(p != myproc()){
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	762080e7          	jalr	1890(ra) # 80001994 <myproc>
    8000223a:	fea488e3          	beq	s1,a0,8000222a <wakeup+0x38>
      acquire(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	996080e7          	jalr	-1642(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002248:	4c9c                	lw	a5,24(s1)
    8000224a:	fd379be3          	bne	a5,s3,80002220 <wakeup+0x2e>
    8000224e:	709c                	ld	a5,32(s1)
    80002250:	fd4798e3          	bne	a5,s4,80002220 <wakeup+0x2e>
    80002254:	b7e1                	j	8000221c <wakeup+0x2a>
    }
  }
}
    80002256:	70e2                	ld	ra,56(sp)
    80002258:	7442                	ld	s0,48(sp)
    8000225a:	74a2                	ld	s1,40(sp)
    8000225c:	7902                	ld	s2,32(sp)
    8000225e:	69e2                	ld	s3,24(sp)
    80002260:	6a42                	ld	s4,16(sp)
    80002262:	6aa2                	ld	s5,8(sp)
    80002264:	6121                	addi	sp,sp,64
    80002266:	8082                	ret

0000000080002268 <reparent>:
{
    80002268:	7179                	addi	sp,sp,-48
    8000226a:	f406                	sd	ra,40(sp)
    8000226c:	f022                	sd	s0,32(sp)
    8000226e:	ec26                	sd	s1,24(sp)
    80002270:	e84a                	sd	s2,16(sp)
    80002272:	e44e                	sd	s3,8(sp)
    80002274:	e052                	sd	s4,0(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227a:	0000f497          	auipc	s1,0xf
    8000227e:	45648493          	addi	s1,s1,1110 # 800116d0 <proc>
      pp->parent = initproc;
    80002282:	00007a17          	auipc	s4,0x7
    80002286:	da6a0a13          	addi	s4,s4,-602 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000228a:	00015997          	auipc	s3,0x15
    8000228e:	04698993          	addi	s3,s3,70 # 800172d0 <tickslock>
    80002292:	a029                	j	8000229c <reparent+0x34>
    80002294:	17048493          	addi	s1,s1,368
    80002298:	01348d63          	beq	s1,s3,800022b2 <reparent+0x4a>
    if(pp->parent == p){
    8000229c:	7c9c                	ld	a5,56(s1)
    8000229e:	ff279be3          	bne	a5,s2,80002294 <reparent+0x2c>
      pp->parent = initproc;
    800022a2:	000a3503          	ld	a0,0(s4)
    800022a6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	f4a080e7          	jalr	-182(ra) # 800021f2 <wakeup>
    800022b0:	b7d5                	j	80002294 <reparent+0x2c>
}
    800022b2:	70a2                	ld	ra,40(sp)
    800022b4:	7402                	ld	s0,32(sp)
    800022b6:	64e2                	ld	s1,24(sp)
    800022b8:	6942                	ld	s2,16(sp)
    800022ba:	69a2                	ld	s3,8(sp)
    800022bc:	6a02                	ld	s4,0(sp)
    800022be:	6145                	addi	sp,sp,48
    800022c0:	8082                	ret

00000000800022c2 <exit>:
{
    800022c2:	7179                	addi	sp,sp,-48
    800022c4:	f406                	sd	ra,40(sp)
    800022c6:	f022                	sd	s0,32(sp)
    800022c8:	ec26                	sd	s1,24(sp)
    800022ca:	e84a                	sd	s2,16(sp)
    800022cc:	e44e                	sd	s3,8(sp)
    800022ce:	e052                	sd	s4,0(sp)
    800022d0:	1800                	addi	s0,sp,48
    800022d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	6c0080e7          	jalr	1728(ra) # 80001994 <myproc>
    800022dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022de:	00007797          	auipc	a5,0x7
    800022e2:	d4a7b783          	ld	a5,-694(a5) # 80009028 <initproc>
    800022e6:	0d050493          	addi	s1,a0,208
    800022ea:	15050913          	addi	s2,a0,336
    800022ee:	02a79363          	bne	a5,a0,80002314 <exit+0x52>
    panic("init exiting");
    800022f2:	00006517          	auipc	a0,0x6
    800022f6:	f5650513          	addi	a0,a0,-170 # 80008248 <digits+0x208>
    800022fa:	ffffe097          	auipc	ra,0xffffe
    800022fe:	236080e7          	jalr	566(ra) # 80000530 <panic>
      fileclose(f);
    80002302:	00002097          	auipc	ra,0x2
    80002306:	47c080e7          	jalr	1148(ra) # 8000477e <fileclose>
      p->ofile[fd] = 0;
    8000230a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000230e:	04a1                	addi	s1,s1,8
    80002310:	01248563          	beq	s1,s2,8000231a <exit+0x58>
    if(p->ofile[fd]){
    80002314:	6088                	ld	a0,0(s1)
    80002316:	f575                	bnez	a0,80002302 <exit+0x40>
    80002318:	bfdd                	j	8000230e <exit+0x4c>
  begin_op();
    8000231a:	00002097          	auipc	ra,0x2
    8000231e:	f98080e7          	jalr	-104(ra) # 800042b2 <begin_op>
  iput(p->cwd);
    80002322:	1509b503          	ld	a0,336(s3)
    80002326:	00001097          	auipc	ra,0x1
    8000232a:	774080e7          	jalr	1908(ra) # 80003a9a <iput>
  end_op();
    8000232e:	00002097          	auipc	ra,0x2
    80002332:	004080e7          	jalr	4(ra) # 80004332 <end_op>
  p->cwd = 0;
    80002336:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000233a:	0000f497          	auipc	s1,0xf
    8000233e:	f7e48493          	addi	s1,s1,-130 # 800112b8 <wait_lock>
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	892080e7          	jalr	-1902(ra) # 80000bd6 <acquire>
  reparent(p);
    8000234c:	854e                	mv	a0,s3
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	f1a080e7          	jalr	-230(ra) # 80002268 <reparent>
  wakeup(p->parent);
    80002356:	0389b503          	ld	a0,56(s3)
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	e98080e7          	jalr	-360(ra) # 800021f2 <wakeup>
  acquire(&p->lock);
    80002362:	854e                	mv	a0,s3
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	872080e7          	jalr	-1934(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000236c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002370:	4795                	li	a5,5
    80002372:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	912080e7          	jalr	-1774(ra) # 80000c8a <release>
  sched();
    80002380:	00000097          	auipc	ra,0x0
    80002384:	bd4080e7          	jalr	-1068(ra) # 80001f54 <sched>
  panic("zombie exit");
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	ed050513          	addi	a0,a0,-304 # 80008258 <digits+0x218>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	1a0080e7          	jalr	416(ra) # 80000530 <panic>

0000000080002398 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002398:	7179                	addi	sp,sp,-48
    8000239a:	f406                	sd	ra,40(sp)
    8000239c:	f022                	sd	s0,32(sp)
    8000239e:	ec26                	sd	s1,24(sp)
    800023a0:	e84a                	sd	s2,16(sp)
    800023a2:	e44e                	sd	s3,8(sp)
    800023a4:	1800                	addi	s0,sp,48
    800023a6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023a8:	0000f497          	auipc	s1,0xf
    800023ac:	32848493          	addi	s1,s1,808 # 800116d0 <proc>
    800023b0:	00015997          	auipc	s3,0x15
    800023b4:	f2098993          	addi	s3,s3,-224 # 800172d0 <tickslock>
    acquire(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	81c080e7          	jalr	-2020(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800023c2:	589c                	lw	a5,48(s1)
    800023c4:	01278d63          	beq	a5,s2,800023de <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8c0080e7          	jalr	-1856(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023d2:	17048493          	addi	s1,s1,368
    800023d6:	ff3491e3          	bne	s1,s3,800023b8 <kill+0x20>
  }
  return -1;
    800023da:	557d                	li	a0,-1
    800023dc:	a829                	j	800023f6 <kill+0x5e>
      p->killed = 1;
    800023de:	4785                	li	a5,1
    800023e0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023e2:	4c98                	lw	a4,24(s1)
    800023e4:	4789                	li	a5,2
    800023e6:	00f70f63          	beq	a4,a5,80002404 <kill+0x6c>
      release(&p->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	89e080e7          	jalr	-1890(ra) # 80000c8a <release>
      return 0;
    800023f4:	4501                	li	a0,0
}
    800023f6:	70a2                	ld	ra,40(sp)
    800023f8:	7402                	ld	s0,32(sp)
    800023fa:	64e2                	ld	s1,24(sp)
    800023fc:	6942                	ld	s2,16(sp)
    800023fe:	69a2                	ld	s3,8(sp)
    80002400:	6145                	addi	sp,sp,48
    80002402:	8082                	ret
        p->state = RUNNABLE;
    80002404:	478d                	li	a5,3
    80002406:	cc9c                	sw	a5,24(s1)
    80002408:	b7cd                	j	800023ea <kill+0x52>

000000008000240a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000240a:	7179                	addi	sp,sp,-48
    8000240c:	f406                	sd	ra,40(sp)
    8000240e:	f022                	sd	s0,32(sp)
    80002410:	ec26                	sd	s1,24(sp)
    80002412:	e84a                	sd	s2,16(sp)
    80002414:	e44e                	sd	s3,8(sp)
    80002416:	e052                	sd	s4,0(sp)
    80002418:	1800                	addi	s0,sp,48
    8000241a:	84aa                	mv	s1,a0
    8000241c:	892e                	mv	s2,a1
    8000241e:	89b2                	mv	s3,a2
    80002420:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	572080e7          	jalr	1394(ra) # 80001994 <myproc>
  if(user_dst){
    8000242a:	c08d                	beqz	s1,8000244c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000242c:	86d2                	mv	a3,s4
    8000242e:	864e                	mv	a2,s3
    80002430:	85ca                	mv	a1,s2
    80002432:	6928                	ld	a0,80(a0)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	222080e7          	jalr	546(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000243c:	70a2                	ld	ra,40(sp)
    8000243e:	7402                	ld	s0,32(sp)
    80002440:	64e2                	ld	s1,24(sp)
    80002442:	6942                	ld	s2,16(sp)
    80002444:	69a2                	ld	s3,8(sp)
    80002446:	6a02                	ld	s4,0(sp)
    80002448:	6145                	addi	sp,sp,48
    8000244a:	8082                	ret
    memmove((char *)dst, src, len);
    8000244c:	000a061b          	sext.w	a2,s4
    80002450:	85ce                	mv	a1,s3
    80002452:	854a                	mv	a0,s2
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	8de080e7          	jalr	-1826(ra) # 80000d32 <memmove>
    return 0;
    8000245c:	8526                	mv	a0,s1
    8000245e:	bff9                	j	8000243c <either_copyout+0x32>

0000000080002460 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	e052                	sd	s4,0(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	892a                	mv	s2,a0
    80002472:	84ae                	mv	s1,a1
    80002474:	89b2                	mv	s3,a2
    80002476:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	51c080e7          	jalr	1308(ra) # 80001994 <myproc>
  if(user_src){
    80002480:	c08d                	beqz	s1,800024a2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002482:	86d2                	mv	a3,s4
    80002484:	864e                	mv	a2,s3
    80002486:	85ca                	mv	a1,s2
    80002488:	6928                	ld	a0,80(a0)
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	258080e7          	jalr	600(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6a02                	ld	s4,0(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret
    memmove(dst, (char*)src, len);
    800024a2:	000a061b          	sext.w	a2,s4
    800024a6:	85ce                	mv	a1,s3
    800024a8:	854a                	mv	a0,s2
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	888080e7          	jalr	-1912(ra) # 80000d32 <memmove>
    return 0;
    800024b2:	8526                	mv	a0,s1
    800024b4:	bff9                	j	80002492 <either_copyin+0x32>

00000000800024b6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024b6:	715d                	addi	sp,sp,-80
    800024b8:	e486                	sd	ra,72(sp)
    800024ba:	e0a2                	sd	s0,64(sp)
    800024bc:	fc26                	sd	s1,56(sp)
    800024be:	f84a                	sd	s2,48(sp)
    800024c0:	f44e                	sd	s3,40(sp)
    800024c2:	f052                	sd	s4,32(sp)
    800024c4:	ec56                	sd	s5,24(sp)
    800024c6:	e85a                	sd	s6,16(sp)
    800024c8:	e45e                	sd	s7,8(sp)
    800024ca:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024cc:	00006517          	auipc	a0,0x6
    800024d0:	bfc50513          	addi	a0,a0,-1028 # 800080c8 <digits+0x88>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	0a6080e7          	jalr	166(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024dc:	0000f497          	auipc	s1,0xf
    800024e0:	34c48493          	addi	s1,s1,844 # 80011828 <proc+0x158>
    800024e4:	00015917          	auipc	s2,0x15
    800024e8:	f4490913          	addi	s2,s2,-188 # 80017428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024ec:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024ee:	00006997          	auipc	s3,0x6
    800024f2:	d7a98993          	addi	s3,s3,-646 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024f6:	00006a97          	auipc	s5,0x6
    800024fa:	d7aa8a93          	addi	s5,s5,-646 # 80008270 <digits+0x230>
    printf("\n");
    800024fe:	00006a17          	auipc	s4,0x6
    80002502:	bcaa0a13          	addi	s4,s4,-1078 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002506:	00006b97          	auipc	s7,0x6
    8000250a:	da2b8b93          	addi	s7,s7,-606 # 800082a8 <states.1715>
    8000250e:	a00d                	j	80002530 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002510:	ed86a583          	lw	a1,-296(a3)
    80002514:	8556                	mv	a0,s5
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	064080e7          	jalr	100(ra) # 8000057a <printf>
    printf("\n");
    8000251e:	8552                	mv	a0,s4
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	05a080e7          	jalr	90(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002528:	17048493          	addi	s1,s1,368
    8000252c:	03248163          	beq	s1,s2,8000254e <procdump+0x98>
    if(p->state == UNUSED)
    80002530:	86a6                	mv	a3,s1
    80002532:	ec04a783          	lw	a5,-320(s1)
    80002536:	dbed                	beqz	a5,80002528 <procdump+0x72>
      state = "???";
    80002538:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253a:	fcfb6be3          	bltu	s6,a5,80002510 <procdump+0x5a>
    8000253e:	1782                	slli	a5,a5,0x20
    80002540:	9381                	srli	a5,a5,0x20
    80002542:	078e                	slli	a5,a5,0x3
    80002544:	97de                	add	a5,a5,s7
    80002546:	6390                	ld	a2,0(a5)
    80002548:	f661                	bnez	a2,80002510 <procdump+0x5a>
      state = "???";
    8000254a:	864e                	mv	a2,s3
    8000254c:	b7d1                	j	80002510 <procdump+0x5a>
  }
}
    8000254e:	60a6                	ld	ra,72(sp)
    80002550:	6406                	ld	s0,64(sp)
    80002552:	74e2                	ld	s1,56(sp)
    80002554:	7942                	ld	s2,48(sp)
    80002556:	79a2                	ld	s3,40(sp)
    80002558:	7a02                	ld	s4,32(sp)
    8000255a:	6ae2                	ld	s5,24(sp)
    8000255c:	6b42                	ld	s6,16(sp)
    8000255e:	6ba2                	ld	s7,8(sp)
    80002560:	6161                	addi	sp,sp,80
    80002562:	8082                	ret

0000000080002564 <ps>:

int ps(uint64 addr) {
    80002564:	7125                	addi	sp,sp,-416
    80002566:	ef06                	sd	ra,408(sp)
    80002568:	eb22                	sd	s0,400(sp)
    8000256a:	e726                	sd	s1,392(sp)
    8000256c:	e34a                	sd	s2,384(sp)
    8000256e:	fece                	sd	s3,376(sp)
    80002570:	fad2                	sd	s4,368(sp)
    80002572:	f6d6                	sd	s5,360(sp)
    80002574:	f2da                	sd	s6,352(sp)
    80002576:	eede                	sd	s7,344(sp)
    80002578:	eae2                	sd	s8,336(sp)
    8000257a:	e6e6                	sd	s9,328(sp)
    8000257c:	e2ea                	sd	s10,320(sp)
    8000257e:	fe6e                	sd	s11,312(sp)
    80002580:	1300                	addi	s0,sp,416
    80002582:	e6a43423          	sd	a0,-408(s0)
  struct ps_proc data[MAX_PROC];
  struct proc *p;
  
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++) {
    80002586:	e7840913          	addi	s2,s0,-392
int ps(uint64 addr) {
    8000258a:	04000993          	li	s3,64
  for(p = proc; p < &proc[NPROC]; p++) {
    8000258e:	0000f497          	auipc	s1,0xf
    80002592:	14248493          	addi	s1,s1,322 # 800116d0 <proc>
    if(p->state == USED) {
    80002596:	4a05                	li	s4,1
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == SLEEPING) {
    80002598:	4a89                	li	s5,2
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == RUNNABLE) {
    8000259a:	4b0d                	li	s6,3
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == RUNNING) {
    8000259c:	4b91                	li	s7,4
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == ZOMBIE) {
    8000259e:	4c15                	li	s8,5
      data[i].state = 5;
    800025a0:	4c95                	li	s9,5
      data[i].state = 4;
    800025a2:	4d91                	li	s11,4
      data[i].state = 3;
    800025a4:	4d0d                	li	s10,3
    800025a6:	a815                	j	800025da <ps+0x76>
      data[i].state = 1;
    800025a8:	4785                	li	a5,1
    800025aa:	00f92023          	sw	a5,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    800025ae:	4641                	li	a2,16
    800025b0:	15848593          	addi	a1,s1,344
    800025b4:	00c90513          	addi	a0,s2,12
    800025b8:	fffff097          	auipc	ra,0xfffff
    800025bc:	870080e7          	jalr	-1936(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    800025c0:	589c                	lw	a5,48(s1)
    800025c2:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    800025c6:	1684b783          	ld	a5,360(s1)
    800025ca:	00f92423          	sw	a5,8(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800025ce:	17048493          	addi	s1,s1,368
    800025d2:	19fd                	addi	s3,s3,-1
    800025d4:	0971                	addi	s2,s2,28
    800025d6:	0a098a63          	beqz	s3,8000268a <ps+0x126>
    if(p->state == USED) {
    800025da:	4c9c                	lw	a5,24(s1)
    800025dc:	fd4786e3          	beq	a5,s4,800025a8 <ps+0x44>
    else if (p->state == SLEEPING) {
    800025e0:	03578b63          	beq	a5,s5,80002616 <ps+0xb2>
    else if (p->state == RUNNABLE) {
    800025e4:	05678d63          	beq	a5,s6,8000263e <ps+0xda>
    else if (p->state == RUNNING) {
    800025e8:	07778e63          	beq	a5,s7,80002664 <ps+0x100>
    else if (p->state == ZOMBIE) {
    800025ec:	ff8791e3          	bne	a5,s8,800025ce <ps+0x6a>
      data[i].state = 5;
    800025f0:	01992023          	sw	s9,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    800025f4:	4641                	li	a2,16
    800025f6:	15848593          	addi	a1,s1,344
    800025fa:	00c90513          	addi	a0,s2,12
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	82a080e7          	jalr	-2006(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    80002606:	589c                	lw	a5,48(s1)
    80002608:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    8000260c:	1684b783          	ld	a5,360(s1)
    80002610:	00f92423          	sw	a5,8(s2)
      ++i;
    80002614:	bf6d                	j	800025ce <ps+0x6a>
      data[i].state = 2;
    80002616:	4789                	li	a5,2
    80002618:	00f92023          	sw	a5,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    8000261c:	4641                	li	a2,16
    8000261e:	15848593          	addi	a1,s1,344
    80002622:	00c90513          	addi	a0,s2,12
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	802080e7          	jalr	-2046(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    8000262e:	589c                	lw	a5,48(s1)
    80002630:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    80002634:	1684b783          	ld	a5,360(s1)
    80002638:	00f92423          	sw	a5,8(s2)
      ++i;
    8000263c:	bf49                	j	800025ce <ps+0x6a>
      data[i].state = 3;
    8000263e:	01a92023          	sw	s10,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    80002642:	4641                	li	a2,16
    80002644:	15848593          	addi	a1,s1,344
    80002648:	00c90513          	addi	a0,s2,12
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	7dc080e7          	jalr	2012(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    80002654:	589c                	lw	a5,48(s1)
    80002656:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    8000265a:	1684b783          	ld	a5,360(s1)
    8000265e:	00f92423          	sw	a5,8(s2)
      ++i;
    80002662:	b7b5                	j	800025ce <ps+0x6a>
      data[i].state = 4;
    80002664:	01b92023          	sw	s11,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    80002668:	4641                	li	a2,16
    8000266a:	15848593          	addi	a1,s1,344
    8000266e:	00c90513          	addi	a0,s2,12
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	7b6080e7          	jalr	1974(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    8000267a:	589c                	lw	a5,48(s1)
    8000267c:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    80002680:	1684b783          	ld	a5,360(s1)
    80002684:	00f92423          	sw	a5,8(s2)
      ++i;
    80002688:	b799                	j	800025ce <ps+0x6a>
      ++i;
      continue;
    }
  }
    
  if(copyout(myproc()->pagetable, addr, (char *)data, sizeof(data)) < 0) {
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	30a080e7          	jalr	778(ra) # 80001994 <myproc>
    80002692:	11800693          	li	a3,280
    80002696:	e7840613          	addi	a2,s0,-392
    8000269a:	e6843583          	ld	a1,-408(s0)
    8000269e:	6928                	ld	a0,80(a0)
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	fb6080e7          	jalr	-74(ra) # 80001656 <copyout>
    return -1;
  }
  return 1;
    800026a8:	4785                	li	a5,1
  if(copyout(myproc()->pagetable, addr, (char *)data, sizeof(data)) < 0) {
    800026aa:	02054263          	bltz	a0,800026ce <ps+0x16a>
}
    800026ae:	853e                	mv	a0,a5
    800026b0:	60fa                	ld	ra,408(sp)
    800026b2:	645a                	ld	s0,400(sp)
    800026b4:	64ba                	ld	s1,392(sp)
    800026b6:	691a                	ld	s2,384(sp)
    800026b8:	79f6                	ld	s3,376(sp)
    800026ba:	7a56                	ld	s4,368(sp)
    800026bc:	7ab6                	ld	s5,360(sp)
    800026be:	7b16                	ld	s6,352(sp)
    800026c0:	6bf6                	ld	s7,344(sp)
    800026c2:	6c56                	ld	s8,336(sp)
    800026c4:	6cb6                	ld	s9,328(sp)
    800026c6:	6d16                	ld	s10,320(sp)
    800026c8:	7df2                	ld	s11,312(sp)
    800026ca:	611d                	addi	sp,sp,416
    800026cc:	8082                	ret
    return -1;
    800026ce:	57fd                	li	a5,-1
    800026d0:	bff9                	j	800026ae <ps+0x14a>

00000000800026d2 <fork2>:

int fork2(uint64 prio) {
    800026d2:	7179                	addi	sp,sp,-48
    800026d4:	f406                	sd	ra,40(sp)
    800026d6:	f022                	sd	s0,32(sp)
    800026d8:	ec26                	sd	s1,24(sp)
    800026da:	e84a                	sd	s2,16(sp)
    800026dc:	e44e                	sd	s3,8(sp)
    800026de:	e052                	sd	s4,0(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	84aa                	mv	s1,a0
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	2b0080e7          	jalr	688(ra) # 80001994 <myproc>
    800026ec:	892a                	mv	s2,a0

  // Allocate process.
  if((np = allocproc()) == 0){
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	4b0080e7          	jalr	1200(ra) # 80001b9e <allocproc>
    800026f6:	10050f63          	beqz	a0,80002814 <fork2+0x142>
    800026fa:	89aa                	mv	s3,a0
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800026fc:	04893603          	ld	a2,72(s2)
    80002700:	692c                	ld	a1,80(a0)
    80002702:	05093503          	ld	a0,80(s2)
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	e4c080e7          	jalr	-436(ra) # 80001552 <uvmcopy>
    8000270e:	04054a63          	bltz	a0,80002762 <fork2+0x90>
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
    80002712:	04893783          	ld	a5,72(s2)
    80002716:	04f9b423          	sd	a5,72(s3)

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);
    8000271a:	05893683          	ld	a3,88(s2)
    8000271e:	87b6                	mv	a5,a3
    80002720:	0589b703          	ld	a4,88(s3)
    80002724:	12068693          	addi	a3,a3,288
    80002728:	0007b883          	ld	a7,0(a5)
    8000272c:	0087b803          	ld	a6,8(a5)
    80002730:	6b8c                	ld	a1,16(a5)
    80002732:	6f90                	ld	a2,24(a5)
    80002734:	01173023          	sd	a7,0(a4)
    80002738:	01073423          	sd	a6,8(a4)
    8000273c:	eb0c                	sd	a1,16(a4)
    8000273e:	ef10                	sd	a2,24(a4)
    80002740:	02078793          	addi	a5,a5,32
    80002744:	02070713          	addi	a4,a4,32
    80002748:	fed790e3          	bne	a5,a3,80002728 <fork2+0x56>

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;
    8000274c:	0589b783          	ld	a5,88(s3)
    80002750:	0607b823          	sd	zero,112(a5)
  np->priority = prio;
    80002754:	1699b423          	sd	s1,360(s3)
    80002758:	0d000493          	li	s1,208
  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    8000275c:	15000a13          	li	s4,336
    80002760:	a03d                	j	8000278e <fork2+0xbc>
    freeproc(np);
    80002762:	854e                	mv	a0,s3
    80002764:	fffff097          	auipc	ra,0xfffff
    80002768:	3e2080e7          	jalr	994(ra) # 80001b46 <freeproc>
    release(&np->lock);
    8000276c:	854e                	mv	a0,s3
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	51c080e7          	jalr	1308(ra) # 80000c8a <release>
    return -1;
    80002776:	5a7d                	li	s4,-1
    80002778:	a069                	j	80002802 <fork2+0x130>
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
    8000277a:	00002097          	auipc	ra,0x2
    8000277e:	fb2080e7          	jalr	-78(ra) # 8000472c <filedup>
    80002782:	009987b3          	add	a5,s3,s1
    80002786:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002788:	04a1                	addi	s1,s1,8
    8000278a:	01448763          	beq	s1,s4,80002798 <fork2+0xc6>
    if(p->ofile[i])
    8000278e:	009907b3          	add	a5,s2,s1
    80002792:	6388                	ld	a0,0(a5)
    80002794:	f17d                	bnez	a0,8000277a <fork2+0xa8>
    80002796:	bfcd                	j	80002788 <fork2+0xb6>
  np->cwd = idup(p->cwd);
    80002798:	15093503          	ld	a0,336(s2)
    8000279c:	00001097          	auipc	ra,0x1
    800027a0:	106080e7          	jalr	262(ra) # 800038a2 <idup>
    800027a4:	14a9b823          	sd	a0,336(s3)

  safestrcpy(np->name, p->name, sizeof(p->name));
    800027a8:	4641                	li	a2,16
    800027aa:	15890593          	addi	a1,s2,344
    800027ae:	15898513          	addi	a0,s3,344
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	676080e7          	jalr	1654(ra) # 80000e28 <safestrcpy>

  pid = np->pid;
    800027ba:	0309aa03          	lw	s4,48(s3)

  release(&np->lock);
    800027be:	854e                	mv	a0,s3
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4ca080e7          	jalr	1226(ra) # 80000c8a <release>

  acquire(&wait_lock);
    800027c8:	0000f497          	auipc	s1,0xf
    800027cc:	af048493          	addi	s1,s1,-1296 # 800112b8 <wait_lock>
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	404080e7          	jalr	1028(ra) # 80000bd6 <acquire>
  np->parent = p;
    800027da:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4aa080e7          	jalr	1194(ra) # 80000c8a <release>

  acquire(&np->lock);
    800027e8:	854e                	mv	a0,s3
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	3ec080e7          	jalr	1004(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    800027f2:	478d                	li	a5,3
    800027f4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800027f8:	854e                	mv	a0,s3
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	490080e7          	jalr	1168(ra) # 80000c8a <release>

  return pid;
}
    80002802:	8552                	mv	a0,s4
    80002804:	70a2                	ld	ra,40(sp)
    80002806:	7402                	ld	s0,32(sp)
    80002808:	64e2                	ld	s1,24(sp)
    8000280a:	6942                	ld	s2,16(sp)
    8000280c:	69a2                	ld	s3,8(sp)
    8000280e:	6a02                	ld	s4,0(sp)
    80002810:	6145                	addi	sp,sp,48
    80002812:	8082                	ret
    return -1;
    80002814:	5a7d                	li	s4,-1
    80002816:	b7f5                	j	80002802 <fork2+0x130>

0000000080002818 <swtch>:
    80002818:	00153023          	sd	ra,0(a0)
    8000281c:	00253423          	sd	sp,8(a0)
    80002820:	e900                	sd	s0,16(a0)
    80002822:	ed04                	sd	s1,24(a0)
    80002824:	03253023          	sd	s2,32(a0)
    80002828:	03353423          	sd	s3,40(a0)
    8000282c:	03453823          	sd	s4,48(a0)
    80002830:	03553c23          	sd	s5,56(a0)
    80002834:	05653023          	sd	s6,64(a0)
    80002838:	05753423          	sd	s7,72(a0)
    8000283c:	05853823          	sd	s8,80(a0)
    80002840:	05953c23          	sd	s9,88(a0)
    80002844:	07a53023          	sd	s10,96(a0)
    80002848:	07b53423          	sd	s11,104(a0)
    8000284c:	0005b083          	ld	ra,0(a1)
    80002850:	0085b103          	ld	sp,8(a1)
    80002854:	6980                	ld	s0,16(a1)
    80002856:	6d84                	ld	s1,24(a1)
    80002858:	0205b903          	ld	s2,32(a1)
    8000285c:	0285b983          	ld	s3,40(a1)
    80002860:	0305ba03          	ld	s4,48(a1)
    80002864:	0385ba83          	ld	s5,56(a1)
    80002868:	0405bb03          	ld	s6,64(a1)
    8000286c:	0485bb83          	ld	s7,72(a1)
    80002870:	0505bc03          	ld	s8,80(a1)
    80002874:	0585bc83          	ld	s9,88(a1)
    80002878:	0605bd03          	ld	s10,96(a1)
    8000287c:	0685bd83          	ld	s11,104(a1)
    80002880:	8082                	ret

0000000080002882 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002882:	1141                	addi	sp,sp,-16
    80002884:	e406                	sd	ra,8(sp)
    80002886:	e022                	sd	s0,0(sp)
    80002888:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000288a:	00006597          	auipc	a1,0x6
    8000288e:	a4e58593          	addi	a1,a1,-1458 # 800082d8 <states.1715+0x30>
    80002892:	00015517          	auipc	a0,0x15
    80002896:	a3e50513          	addi	a0,a0,-1474 # 800172d0 <tickslock>
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	2ac080e7          	jalr	684(ra) # 80000b46 <initlock>
}
    800028a2:	60a2                	ld	ra,8(sp)
    800028a4:	6402                	ld	s0,0(sp)
    800028a6:	0141                	addi	sp,sp,16
    800028a8:	8082                	ret

00000000800028aa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028aa:	1141                	addi	sp,sp,-16
    800028ac:	e422                	sd	s0,8(sp)
    800028ae:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b0:	00003797          	auipc	a5,0x3
    800028b4:	4f078793          	addi	a5,a5,1264 # 80005da0 <kernelvec>
    800028b8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028bc:	6422                	ld	s0,8(sp)
    800028be:	0141                	addi	sp,sp,16
    800028c0:	8082                	ret

00000000800028c2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028c2:	1141                	addi	sp,sp,-16
    800028c4:	e406                	sd	ra,8(sp)
    800028c6:	e022                	sd	s0,0(sp)
    800028c8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ca:	fffff097          	auipc	ra,0xfffff
    800028ce:	0ca080e7          	jalr	202(ra) # 80001994 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028d6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028dc:	00004617          	auipc	a2,0x4
    800028e0:	72460613          	addi	a2,a2,1828 # 80007000 <_trampoline>
    800028e4:	00004697          	auipc	a3,0x4
    800028e8:	71c68693          	addi	a3,a3,1820 # 80007000 <_trampoline>
    800028ec:	8e91                	sub	a3,a3,a2
    800028ee:	040007b7          	lui	a5,0x4000
    800028f2:	17fd                	addi	a5,a5,-1
    800028f4:	07b2                	slli	a5,a5,0xc
    800028f6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028fc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028fe:	180026f3          	csrr	a3,satp
    80002902:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002904:	6d38                	ld	a4,88(a0)
    80002906:	6134                	ld	a3,64(a0)
    80002908:	6585                	lui	a1,0x1
    8000290a:	96ae                	add	a3,a3,a1
    8000290c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000290e:	6d38                	ld	a4,88(a0)
    80002910:	00000697          	auipc	a3,0x0
    80002914:	13868693          	addi	a3,a3,312 # 80002a48 <usertrap>
    80002918:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000291a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000291c:	8692                	mv	a3,tp
    8000291e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002924:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002928:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000292c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002930:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002932:	6f18                	ld	a4,24(a4)
    80002934:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002938:	692c                	ld	a1,80(a0)
    8000293a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000293c:	00004717          	auipc	a4,0x4
    80002940:	75470713          	addi	a4,a4,1876 # 80007090 <userret>
    80002944:	8f11                	sub	a4,a4,a2
    80002946:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002948:	577d                	li	a4,-1
    8000294a:	177e                	slli	a4,a4,0x3f
    8000294c:	8dd9                	or	a1,a1,a4
    8000294e:	02000537          	lui	a0,0x2000
    80002952:	157d                	addi	a0,a0,-1
    80002954:	0536                	slli	a0,a0,0xd
    80002956:	9782                	jalr	a5
}
    80002958:	60a2                	ld	ra,8(sp)
    8000295a:	6402                	ld	s0,0(sp)
    8000295c:	0141                	addi	sp,sp,16
    8000295e:	8082                	ret

0000000080002960 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002960:	1101                	addi	sp,sp,-32
    80002962:	ec06                	sd	ra,24(sp)
    80002964:	e822                	sd	s0,16(sp)
    80002966:	e426                	sd	s1,8(sp)
    80002968:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000296a:	00015497          	auipc	s1,0x15
    8000296e:	96648493          	addi	s1,s1,-1690 # 800172d0 <tickslock>
    80002972:	8526                	mv	a0,s1
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	262080e7          	jalr	610(ra) # 80000bd6 <acquire>
  ticks++;
    8000297c:	00006517          	auipc	a0,0x6
    80002980:	6b450513          	addi	a0,a0,1716 # 80009030 <ticks>
    80002984:	411c                	lw	a5,0(a0)
    80002986:	2785                	addiw	a5,a5,1
    80002988:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	868080e7          	jalr	-1944(ra) # 800021f2 <wakeup>
  release(&tickslock);
    80002992:	8526                	mv	a0,s1
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	2f6080e7          	jalr	758(ra) # 80000c8a <release>
}
    8000299c:	60e2                	ld	ra,24(sp)
    8000299e:	6442                	ld	s0,16(sp)
    800029a0:	64a2                	ld	s1,8(sp)
    800029a2:	6105                	addi	sp,sp,32
    800029a4:	8082                	ret

00000000800029a6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029a6:	1101                	addi	sp,sp,-32
    800029a8:	ec06                	sd	ra,24(sp)
    800029aa:	e822                	sd	s0,16(sp)
    800029ac:	e426                	sd	s1,8(sp)
    800029ae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029b4:	00074d63          	bltz	a4,800029ce <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029b8:	57fd                	li	a5,-1
    800029ba:	17fe                	slli	a5,a5,0x3f
    800029bc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029be:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029c0:	06f70363          	beq	a4,a5,80002a26 <devintr+0x80>
  }
}
    800029c4:	60e2                	ld	ra,24(sp)
    800029c6:	6442                	ld	s0,16(sp)
    800029c8:	64a2                	ld	s1,8(sp)
    800029ca:	6105                	addi	sp,sp,32
    800029cc:	8082                	ret
     (scause & 0xff) == 9){
    800029ce:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029d2:	46a5                	li	a3,9
    800029d4:	fed792e3          	bne	a5,a3,800029b8 <devintr+0x12>
    int irq = plic_claim();
    800029d8:	00003097          	auipc	ra,0x3
    800029dc:	4d0080e7          	jalr	1232(ra) # 80005ea8 <plic_claim>
    800029e0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029e2:	47a9                	li	a5,10
    800029e4:	02f50763          	beq	a0,a5,80002a12 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029e8:	4785                	li	a5,1
    800029ea:	02f50963          	beq	a0,a5,80002a1c <devintr+0x76>
    return 1;
    800029ee:	4505                	li	a0,1
    } else if(irq){
    800029f0:	d8f1                	beqz	s1,800029c4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029f2:	85a6                	mv	a1,s1
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	8ec50513          	addi	a0,a0,-1812 # 800082e0 <states.1715+0x38>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b7e080e7          	jalr	-1154(ra) # 8000057a <printf>
      plic_complete(irq);
    80002a04:	8526                	mv	a0,s1
    80002a06:	00003097          	auipc	ra,0x3
    80002a0a:	4c6080e7          	jalr	1222(ra) # 80005ecc <plic_complete>
    return 1;
    80002a0e:	4505                	li	a0,1
    80002a10:	bf55                	j	800029c4 <devintr+0x1e>
      uartintr();
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	f88080e7          	jalr	-120(ra) # 8000099a <uartintr>
    80002a1a:	b7ed                	j	80002a04 <devintr+0x5e>
      virtio_disk_intr();
    80002a1c:	00004097          	auipc	ra,0x4
    80002a20:	990080e7          	jalr	-1648(ra) # 800063ac <virtio_disk_intr>
    80002a24:	b7c5                	j	80002a04 <devintr+0x5e>
    if(cpuid() == 0){
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	f42080e7          	jalr	-190(ra) # 80001968 <cpuid>
    80002a2e:	c901                	beqz	a0,80002a3e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a30:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a36:	14479073          	csrw	sip,a5
    return 2;
    80002a3a:	4509                	li	a0,2
    80002a3c:	b761                	j	800029c4 <devintr+0x1e>
      clockintr();
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	f22080e7          	jalr	-222(ra) # 80002960 <clockintr>
    80002a46:	b7ed                	j	80002a30 <devintr+0x8a>

0000000080002a48 <usertrap>:
{
    80002a48:	1101                	addi	sp,sp,-32
    80002a4a:	ec06                	sd	ra,24(sp)
    80002a4c:	e822                	sd	s0,16(sp)
    80002a4e:	e426                	sd	s1,8(sp)
    80002a50:	e04a                	sd	s2,0(sp)
    80002a52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a54:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a58:	1007f793          	andi	a5,a5,256
    80002a5c:	e3ad                	bnez	a5,80002abe <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a5e:	00003797          	auipc	a5,0x3
    80002a62:	34278793          	addi	a5,a5,834 # 80005da0 <kernelvec>
    80002a66:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	f2a080e7          	jalr	-214(ra) # 80001994 <myproc>
    80002a72:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a74:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a76:	14102773          	csrr	a4,sepc
    80002a7a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a7c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a80:	47a1                	li	a5,8
    80002a82:	04f71c63          	bne	a4,a5,80002ada <usertrap+0x92>
    if(p->killed)
    80002a86:	551c                	lw	a5,40(a0)
    80002a88:	e3b9                	bnez	a5,80002ace <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a8a:	6cb8                	ld	a4,88(s1)
    80002a8c:	6f1c                	ld	a5,24(a4)
    80002a8e:	0791                	addi	a5,a5,4
    80002a90:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a96:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a9a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	2e0080e7          	jalr	736(ra) # 80002d7e <syscall>
  if(p->killed)
    80002aa6:	549c                	lw	a5,40(s1)
    80002aa8:	ebc1                	bnez	a5,80002b38 <usertrap+0xf0>
  usertrapret();
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	e18080e7          	jalr	-488(ra) # 800028c2 <usertrapret>
}
    80002ab2:	60e2                	ld	ra,24(sp)
    80002ab4:	6442                	ld	s0,16(sp)
    80002ab6:	64a2                	ld	s1,8(sp)
    80002ab8:	6902                	ld	s2,0(sp)
    80002aba:	6105                	addi	sp,sp,32
    80002abc:	8082                	ret
    panic("usertrap: not from user mode");
    80002abe:	00006517          	auipc	a0,0x6
    80002ac2:	84250513          	addi	a0,a0,-1982 # 80008300 <states.1715+0x58>
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	a6a080e7          	jalr	-1430(ra) # 80000530 <panic>
      exit(-1);
    80002ace:	557d                	li	a0,-1
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	7f2080e7          	jalr	2034(ra) # 800022c2 <exit>
    80002ad8:	bf4d                	j	80002a8a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	ecc080e7          	jalr	-308(ra) # 800029a6 <devintr>
    80002ae2:	892a                	mv	s2,a0
    80002ae4:	c501                	beqz	a0,80002aec <usertrap+0xa4>
  if(p->killed)
    80002ae6:	549c                	lw	a5,40(s1)
    80002ae8:	c3a1                	beqz	a5,80002b28 <usertrap+0xe0>
    80002aea:	a815                	j	80002b1e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aec:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002af0:	5890                	lw	a2,48(s1)
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	82e50513          	addi	a0,a0,-2002 # 80008320 <states.1715+0x78>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a80080e7          	jalr	-1408(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b06:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	84650513          	addi	a0,a0,-1978 # 80008350 <states.1715+0xa8>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a68080e7          	jalr	-1432(ra) # 8000057a <printf>
    p->killed = 1;
    80002b1a:	4785                	li	a5,1
    80002b1c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b1e:	557d                	li	a0,-1
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	7a2080e7          	jalr	1954(ra) # 800022c2 <exit>
  if(which_dev == 2)
    80002b28:	4789                	li	a5,2
    80002b2a:	f8f910e3          	bne	s2,a5,80002aaa <usertrap+0x62>
    yield();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	4fc080e7          	jalr	1276(ra) # 8000202a <yield>
    80002b36:	bf95                	j	80002aaa <usertrap+0x62>
  int which_dev = 0;
    80002b38:	4901                	li	s2,0
    80002b3a:	b7d5                	j	80002b1e <usertrap+0xd6>

0000000080002b3c <kerneltrap>:
{
    80002b3c:	7179                	addi	sp,sp,-48
    80002b3e:	f406                	sd	ra,40(sp)
    80002b40:	f022                	sd	s0,32(sp)
    80002b42:	ec26                	sd	s1,24(sp)
    80002b44:	e84a                	sd	s2,16(sp)
    80002b46:	e44e                	sd	s3,8(sp)
    80002b48:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b4a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b52:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b56:	1004f793          	andi	a5,s1,256
    80002b5a:	cb85                	beqz	a5,80002b8a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b60:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b62:	ef85                	bnez	a5,80002b9a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	e42080e7          	jalr	-446(ra) # 800029a6 <devintr>
    80002b6c:	cd1d                	beqz	a0,80002baa <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b6e:	4789                	li	a5,2
    80002b70:	06f50a63          	beq	a0,a5,80002be4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b74:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b78:	10049073          	csrw	sstatus,s1
}
    80002b7c:	70a2                	ld	ra,40(sp)
    80002b7e:	7402                	ld	s0,32(sp)
    80002b80:	64e2                	ld	s1,24(sp)
    80002b82:	6942                	ld	s2,16(sp)
    80002b84:	69a2                	ld	s3,8(sp)
    80002b86:	6145                	addi	sp,sp,48
    80002b88:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b8a:	00005517          	auipc	a0,0x5
    80002b8e:	7e650513          	addi	a0,a0,2022 # 80008370 <states.1715+0xc8>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	99e080e7          	jalr	-1634(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b9a:	00005517          	auipc	a0,0x5
    80002b9e:	7fe50513          	addi	a0,a0,2046 # 80008398 <states.1715+0xf0>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	98e080e7          	jalr	-1650(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002baa:	85ce                	mv	a1,s3
    80002bac:	00006517          	auipc	a0,0x6
    80002bb0:	80c50513          	addi	a0,a0,-2036 # 800083b8 <states.1715+0x110>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	9c6080e7          	jalr	-1594(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bbc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bc4:	00006517          	auipc	a0,0x6
    80002bc8:	80450513          	addi	a0,a0,-2044 # 800083c8 <states.1715+0x120>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9ae080e7          	jalr	-1618(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002bd4:	00006517          	auipc	a0,0x6
    80002bd8:	80c50513          	addi	a0,a0,-2036 # 800083e0 <states.1715+0x138>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	954080e7          	jalr	-1708(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	db0080e7          	jalr	-592(ra) # 80001994 <myproc>
    80002bec:	d541                	beqz	a0,80002b74 <kerneltrap+0x38>
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	da6080e7          	jalr	-602(ra) # 80001994 <myproc>
    80002bf6:	4d18                	lw	a4,24(a0)
    80002bf8:	4791                	li	a5,4
    80002bfa:	f6f71de3          	bne	a4,a5,80002b74 <kerneltrap+0x38>
    yield();
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	42c080e7          	jalr	1068(ra) # 8000202a <yield>
    80002c06:	b7bd                	j	80002b74 <kerneltrap+0x38>

0000000080002c08 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c08:	1101                	addi	sp,sp,-32
    80002c0a:	ec06                	sd	ra,24(sp)
    80002c0c:	e822                	sd	s0,16(sp)
    80002c0e:	e426                	sd	s1,8(sp)
    80002c10:	1000                	addi	s0,sp,32
    80002c12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	d80080e7          	jalr	-640(ra) # 80001994 <myproc>
  switch (n) {
    80002c1c:	4795                	li	a5,5
    80002c1e:	0497e163          	bltu	a5,s1,80002c60 <argraw+0x58>
    80002c22:	048a                	slli	s1,s1,0x2
    80002c24:	00005717          	auipc	a4,0x5
    80002c28:	7f470713          	addi	a4,a4,2036 # 80008418 <states.1715+0x170>
    80002c2c:	94ba                	add	s1,s1,a4
    80002c2e:	409c                	lw	a5,0(s1)
    80002c30:	97ba                	add	a5,a5,a4
    80002c32:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c34:	6d3c                	ld	a5,88(a0)
    80002c36:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c38:	60e2                	ld	ra,24(sp)
    80002c3a:	6442                	ld	s0,16(sp)
    80002c3c:	64a2                	ld	s1,8(sp)
    80002c3e:	6105                	addi	sp,sp,32
    80002c40:	8082                	ret
    return p->trapframe->a1;
    80002c42:	6d3c                	ld	a5,88(a0)
    80002c44:	7fa8                	ld	a0,120(a5)
    80002c46:	bfcd                	j	80002c38 <argraw+0x30>
    return p->trapframe->a2;
    80002c48:	6d3c                	ld	a5,88(a0)
    80002c4a:	63c8                	ld	a0,128(a5)
    80002c4c:	b7f5                	j	80002c38 <argraw+0x30>
    return p->trapframe->a3;
    80002c4e:	6d3c                	ld	a5,88(a0)
    80002c50:	67c8                	ld	a0,136(a5)
    80002c52:	b7dd                	j	80002c38 <argraw+0x30>
    return p->trapframe->a4;
    80002c54:	6d3c                	ld	a5,88(a0)
    80002c56:	6bc8                	ld	a0,144(a5)
    80002c58:	b7c5                	j	80002c38 <argraw+0x30>
    return p->trapframe->a5;
    80002c5a:	6d3c                	ld	a5,88(a0)
    80002c5c:	6fc8                	ld	a0,152(a5)
    80002c5e:	bfe9                	j	80002c38 <argraw+0x30>
  panic("argraw");
    80002c60:	00005517          	auipc	a0,0x5
    80002c64:	79050513          	addi	a0,a0,1936 # 800083f0 <states.1715+0x148>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	8c8080e7          	jalr	-1848(ra) # 80000530 <panic>

0000000080002c70 <fetchaddr>:
{
    80002c70:	1101                	addi	sp,sp,-32
    80002c72:	ec06                	sd	ra,24(sp)
    80002c74:	e822                	sd	s0,16(sp)
    80002c76:	e426                	sd	s1,8(sp)
    80002c78:	e04a                	sd	s2,0(sp)
    80002c7a:	1000                	addi	s0,sp,32
    80002c7c:	84aa                	mv	s1,a0
    80002c7e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	d14080e7          	jalr	-748(ra) # 80001994 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c88:	653c                	ld	a5,72(a0)
    80002c8a:	02f4f863          	bgeu	s1,a5,80002cba <fetchaddr+0x4a>
    80002c8e:	00848713          	addi	a4,s1,8
    80002c92:	02e7e663          	bltu	a5,a4,80002cbe <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c96:	46a1                	li	a3,8
    80002c98:	8626                	mv	a2,s1
    80002c9a:	85ca                	mv	a1,s2
    80002c9c:	6928                	ld	a0,80(a0)
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	a44080e7          	jalr	-1468(ra) # 800016e2 <copyin>
    80002ca6:	00a03533          	snez	a0,a0
    80002caa:	40a00533          	neg	a0,a0
}
    80002cae:	60e2                	ld	ra,24(sp)
    80002cb0:	6442                	ld	s0,16(sp)
    80002cb2:	64a2                	ld	s1,8(sp)
    80002cb4:	6902                	ld	s2,0(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret
    return -1;
    80002cba:	557d                	li	a0,-1
    80002cbc:	bfcd                	j	80002cae <fetchaddr+0x3e>
    80002cbe:	557d                	li	a0,-1
    80002cc0:	b7fd                	j	80002cae <fetchaddr+0x3e>

0000000080002cc2 <fetchstr>:
{
    80002cc2:	7179                	addi	sp,sp,-48
    80002cc4:	f406                	sd	ra,40(sp)
    80002cc6:	f022                	sd	s0,32(sp)
    80002cc8:	ec26                	sd	s1,24(sp)
    80002cca:	e84a                	sd	s2,16(sp)
    80002ccc:	e44e                	sd	s3,8(sp)
    80002cce:	1800                	addi	s0,sp,48
    80002cd0:	892a                	mv	s2,a0
    80002cd2:	84ae                	mv	s1,a1
    80002cd4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	cbe080e7          	jalr	-834(ra) # 80001994 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cde:	86ce                	mv	a3,s3
    80002ce0:	864a                	mv	a2,s2
    80002ce2:	85a6                	mv	a1,s1
    80002ce4:	6928                	ld	a0,80(a0)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	a88080e7          	jalr	-1400(ra) # 8000176e <copyinstr>
  if(err < 0)
    80002cee:	00054763          	bltz	a0,80002cfc <fetchstr+0x3a>
  return strlen(buf);
    80002cf2:	8526                	mv	a0,s1
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	166080e7          	jalr	358(ra) # 80000e5a <strlen>
}
    80002cfc:	70a2                	ld	ra,40(sp)
    80002cfe:	7402                	ld	s0,32(sp)
    80002d00:	64e2                	ld	s1,24(sp)
    80002d02:	6942                	ld	s2,16(sp)
    80002d04:	69a2                	ld	s3,8(sp)
    80002d06:	6145                	addi	sp,sp,48
    80002d08:	8082                	ret

0000000080002d0a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	e426                	sd	s1,8(sp)
    80002d12:	1000                	addi	s0,sp,32
    80002d14:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	ef2080e7          	jalr	-270(ra) # 80002c08 <argraw>
    80002d1e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d20:	4501                	li	a0,0
    80002d22:	60e2                	ld	ra,24(sp)
    80002d24:	6442                	ld	s0,16(sp)
    80002d26:	64a2                	ld	s1,8(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	1000                	addi	s0,sp,32
    80002d36:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	ed0080e7          	jalr	-304(ra) # 80002c08 <argraw>
    80002d40:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d42:	4501                	li	a0,0
    80002d44:	60e2                	ld	ra,24(sp)
    80002d46:	6442                	ld	s0,16(sp)
    80002d48:	64a2                	ld	s1,8(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	e426                	sd	s1,8(sp)
    80002d56:	e04a                	sd	s2,0(sp)
    80002d58:	1000                	addi	s0,sp,32
    80002d5a:	84ae                	mv	s1,a1
    80002d5c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	eaa080e7          	jalr	-342(ra) # 80002c08 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d66:	864a                	mv	a2,s2
    80002d68:	85a6                	mv	a1,s1
    80002d6a:	00000097          	auipc	ra,0x0
    80002d6e:	f58080e7          	jalr	-168(ra) # 80002cc2 <fetchstr>
}
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	64a2                	ld	s1,8(sp)
    80002d78:	6902                	ld	s2,0(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <syscall>:
[SYS_fork2]   sys_fork2,
};

void
syscall(void)
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	e426                	sd	s1,8(sp)
    80002d86:	e04a                	sd	s2,0(sp)
    80002d88:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	c0a080e7          	jalr	-1014(ra) # 80001994 <myproc>
    80002d92:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d94:	05853903          	ld	s2,88(a0)
    80002d98:	0a893783          	ld	a5,168(s2)
    80002d9c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002da0:	37fd                	addiw	a5,a5,-1
    80002da2:	4759                	li	a4,22
    80002da4:	00f76f63          	bltu	a4,a5,80002dc2 <syscall+0x44>
    80002da8:	00369713          	slli	a4,a3,0x3
    80002dac:	00005797          	auipc	a5,0x5
    80002db0:	68478793          	addi	a5,a5,1668 # 80008430 <syscalls>
    80002db4:	97ba                	add	a5,a5,a4
    80002db6:	639c                	ld	a5,0(a5)
    80002db8:	c789                	beqz	a5,80002dc2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002dba:	9782                	jalr	a5
    80002dbc:	06a93823          	sd	a0,112(s2)
    80002dc0:	a839                	j	80002dde <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dc2:	15848613          	addi	a2,s1,344
    80002dc6:	588c                	lw	a1,48(s1)
    80002dc8:	00005517          	auipc	a0,0x5
    80002dcc:	63050513          	addi	a0,a0,1584 # 800083f8 <states.1715+0x150>
    80002dd0:	ffffd097          	auipc	ra,0xffffd
    80002dd4:	7aa080e7          	jalr	1962(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dd8:	6cbc                	ld	a5,88(s1)
    80002dda:	577d                	li	a4,-1
    80002ddc:	fbb8                	sd	a4,112(a5)
  }
}
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	64a2                	ld	s1,8(sp)
    80002de4:	6902                	ld	s2,0(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002df2:	fec40593          	addi	a1,s0,-20
    80002df6:	4501                	li	a0,0
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	f12080e7          	jalr	-238(ra) # 80002d0a <argint>
    return -1;
    80002e00:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e02:	00054963          	bltz	a0,80002e14 <sys_exit+0x2a>
  exit(n);
    80002e06:	fec42503          	lw	a0,-20(s0)
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	4b8080e7          	jalr	1208(ra) # 800022c2 <exit>
  return 0;  // not reached
    80002e12:	4781                	li	a5,0
}
    80002e14:	853e                	mv	a0,a5
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	6105                	addi	sp,sp,32
    80002e1c:	8082                	ret

0000000080002e1e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e1e:	1141                	addi	sp,sp,-16
    80002e20:	e406                	sd	ra,8(sp)
    80002e22:	e022                	sd	s0,0(sp)
    80002e24:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	b6e080e7          	jalr	-1170(ra) # 80001994 <myproc>
}
    80002e2e:	5908                	lw	a0,48(a0)
    80002e30:	60a2                	ld	ra,8(sp)
    80002e32:	6402                	ld	s0,0(sp)
    80002e34:	0141                	addi	sp,sp,16
    80002e36:	8082                	ret

0000000080002e38 <sys_fork>:

uint64
sys_fork(void)
{
    80002e38:	1141                	addi	sp,sp,-16
    80002e3a:	e406                	sd	ra,8(sp)
    80002e3c:	e022                	sd	s0,0(sp)
    80002e3e:	0800                	addi	s0,sp,16
  return fork();
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	f2c080e7          	jalr	-212(ra) # 80001d6c <fork>
}
    80002e48:	60a2                	ld	ra,8(sp)
    80002e4a:	6402                	ld	s0,0(sp)
    80002e4c:	0141                	addi	sp,sp,16
    80002e4e:	8082                	ret

0000000080002e50 <sys_wait>:

uint64
sys_wait(void)
{
    80002e50:	1101                	addi	sp,sp,-32
    80002e52:	ec06                	sd	ra,24(sp)
    80002e54:	e822                	sd	s0,16(sp)
    80002e56:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e58:	fe840593          	addi	a1,s0,-24
    80002e5c:	4501                	li	a0,0
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	ece080e7          	jalr	-306(ra) # 80002d2c <argaddr>
    80002e66:	87aa                	mv	a5,a0
    return -1;
    80002e68:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e6a:	0007c863          	bltz	a5,80002e7a <sys_wait+0x2a>
  return wait(p);
    80002e6e:	fe843503          	ld	a0,-24(s0)
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	258080e7          	jalr	600(ra) # 800020ca <wait>
}
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e82:	7179                	addi	sp,sp,-48
    80002e84:	f406                	sd	ra,40(sp)
    80002e86:	f022                	sd	s0,32(sp)
    80002e88:	ec26                	sd	s1,24(sp)
    80002e8a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e8c:	fdc40593          	addi	a1,s0,-36
    80002e90:	4501                	li	a0,0
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	e78080e7          	jalr	-392(ra) # 80002d0a <argint>
    80002e9a:	87aa                	mv	a5,a0
    return -1;
    80002e9c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e9e:	0207c063          	bltz	a5,80002ebe <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	af2080e7          	jalr	-1294(ra) # 80001994 <myproc>
    80002eaa:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002eac:	fdc42503          	lw	a0,-36(s0)
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	e48080e7          	jalr	-440(ra) # 80001cf8 <growproc>
    80002eb8:	00054863          	bltz	a0,80002ec8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ebc:	8526                	mv	a0,s1
}
    80002ebe:	70a2                	ld	ra,40(sp)
    80002ec0:	7402                	ld	s0,32(sp)
    80002ec2:	64e2                	ld	s1,24(sp)
    80002ec4:	6145                	addi	sp,sp,48
    80002ec6:	8082                	ret
    return -1;
    80002ec8:	557d                	li	a0,-1
    80002eca:	bfd5                	j	80002ebe <sys_sbrk+0x3c>

0000000080002ecc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ecc:	7139                	addi	sp,sp,-64
    80002ece:	fc06                	sd	ra,56(sp)
    80002ed0:	f822                	sd	s0,48(sp)
    80002ed2:	f426                	sd	s1,40(sp)
    80002ed4:	f04a                	sd	s2,32(sp)
    80002ed6:	ec4e                	sd	s3,24(sp)
    80002ed8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eda:	fcc40593          	addi	a1,s0,-52
    80002ede:	4501                	li	a0,0
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	e2a080e7          	jalr	-470(ra) # 80002d0a <argint>
    return -1;
    80002ee8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eea:	06054563          	bltz	a0,80002f54 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eee:	00014517          	auipc	a0,0x14
    80002ef2:	3e250513          	addi	a0,a0,994 # 800172d0 <tickslock>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	ce0080e7          	jalr	-800(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002efe:	00006917          	auipc	s2,0x6
    80002f02:	13292903          	lw	s2,306(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f06:	fcc42783          	lw	a5,-52(s0)
    80002f0a:	cf85                	beqz	a5,80002f42 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f0c:	00014997          	auipc	s3,0x14
    80002f10:	3c498993          	addi	s3,s3,964 # 800172d0 <tickslock>
    80002f14:	00006497          	auipc	s1,0x6
    80002f18:	11c48493          	addi	s1,s1,284 # 80009030 <ticks>
    if(myproc()->killed){
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	a78080e7          	jalr	-1416(ra) # 80001994 <myproc>
    80002f24:	551c                	lw	a5,40(a0)
    80002f26:	ef9d                	bnez	a5,80002f64 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f28:	85ce                	mv	a1,s3
    80002f2a:	8526                	mv	a0,s1
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	13a080e7          	jalr	314(ra) # 80002066 <sleep>
  while(ticks - ticks0 < n){
    80002f34:	409c                	lw	a5,0(s1)
    80002f36:	412787bb          	subw	a5,a5,s2
    80002f3a:	fcc42703          	lw	a4,-52(s0)
    80002f3e:	fce7efe3          	bltu	a5,a4,80002f1c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f42:	00014517          	auipc	a0,0x14
    80002f46:	38e50513          	addi	a0,a0,910 # 800172d0 <tickslock>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	d40080e7          	jalr	-704(ra) # 80000c8a <release>
  return 0;
    80002f52:	4781                	li	a5,0
}
    80002f54:	853e                	mv	a0,a5
    80002f56:	70e2                	ld	ra,56(sp)
    80002f58:	7442                	ld	s0,48(sp)
    80002f5a:	74a2                	ld	s1,40(sp)
    80002f5c:	7902                	ld	s2,32(sp)
    80002f5e:	69e2                	ld	s3,24(sp)
    80002f60:	6121                	addi	sp,sp,64
    80002f62:	8082                	ret
      release(&tickslock);
    80002f64:	00014517          	auipc	a0,0x14
    80002f68:	36c50513          	addi	a0,a0,876 # 800172d0 <tickslock>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	d1e080e7          	jalr	-738(ra) # 80000c8a <release>
      return -1;
    80002f74:	57fd                	li	a5,-1
    80002f76:	bff9                	j	80002f54 <sys_sleep+0x88>

0000000080002f78 <sys_kill>:

uint64
sys_kill(void)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f80:	fec40593          	addi	a1,s0,-20
    80002f84:	4501                	li	a0,0
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	d84080e7          	jalr	-636(ra) # 80002d0a <argint>
    80002f8e:	87aa                	mv	a5,a0
    return -1;
    80002f90:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f92:	0007c863          	bltz	a5,80002fa2 <sys_kill+0x2a>
  return kill(pid);
    80002f96:	fec42503          	lw	a0,-20(s0)
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	3fe080e7          	jalr	1022(ra) # 80002398 <kill>
}
    80002fa2:	60e2                	ld	ra,24(sp)
    80002fa4:	6442                	ld	s0,16(sp)
    80002fa6:	6105                	addi	sp,sp,32
    80002fa8:	8082                	ret

0000000080002faa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002faa:	1101                	addi	sp,sp,-32
    80002fac:	ec06                	sd	ra,24(sp)
    80002fae:	e822                	sd	s0,16(sp)
    80002fb0:	e426                	sd	s1,8(sp)
    80002fb2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fb4:	00014517          	auipc	a0,0x14
    80002fb8:	31c50513          	addi	a0,a0,796 # 800172d0 <tickslock>
    80002fbc:	ffffe097          	auipc	ra,0xffffe
    80002fc0:	c1a080e7          	jalr	-998(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fc4:	00006497          	auipc	s1,0x6
    80002fc8:	06c4a483          	lw	s1,108(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	30450513          	addi	a0,a0,772 # 800172d0 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	cb6080e7          	jalr	-842(ra) # 80000c8a <release>
  return xticks;
}
    80002fdc:	02049513          	slli	a0,s1,0x20
    80002fe0:	9101                	srli	a0,a0,0x20
    80002fe2:	60e2                	ld	ra,24(sp)
    80002fe4:	6442                	ld	s0,16(sp)
    80002fe6:	64a2                	ld	s1,8(sp)
    80002fe8:	6105                	addi	sp,sp,32
    80002fea:	8082                	ret

0000000080002fec <sys_ps>:

uint64
sys_ps(void) {
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	1000                	addi	s0,sp,32
  uint64 addr;
  if(argaddr(0, &addr) < 0) return -1;
    80002ff4:	fe840593          	addi	a1,s0,-24
    80002ff8:	4501                	li	a0,0
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	d32080e7          	jalr	-718(ra) # 80002d2c <argaddr>
    80003002:	87aa                	mv	a5,a0
    80003004:	557d                	li	a0,-1
    80003006:	0007c863          	bltz	a5,80003016 <sys_ps+0x2a>

  return ps(addr);
    8000300a:	fe843503          	ld	a0,-24(s0)
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	556080e7          	jalr	1366(ra) # 80002564 <ps>
}
    80003016:	60e2                	ld	ra,24(sp)
    80003018:	6442                	ld	s0,16(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret

000000008000301e <sys_fork2>:

uint64 sys_fork2(void) {
    8000301e:	1101                	addi	sp,sp,-32
    80003020:	ec06                	sd	ra,24(sp)
    80003022:	e822                	sd	s0,16(sp)
    80003024:	1000                	addi	s0,sp,32
  int prio;
  if(argint(0, &prio) < 0) return -1;
    80003026:	fec40593          	addi	a1,s0,-20
    8000302a:	4501                	li	a0,0
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	cde080e7          	jalr	-802(ra) # 80002d0a <argint>
    80003034:	87aa                	mv	a5,a0
    80003036:	557d                	li	a0,-1
    80003038:	0007c863          	bltz	a5,80003048 <sys_fork2+0x2a>
  return fork2(prio);
    8000303c:	fec42503          	lw	a0,-20(s0)
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	692080e7          	jalr	1682(ra) # 800026d2 <fork2>
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret

0000000080003050 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003050:	7179                	addi	sp,sp,-48
    80003052:	f406                	sd	ra,40(sp)
    80003054:	f022                	sd	s0,32(sp)
    80003056:	ec26                	sd	s1,24(sp)
    80003058:	e84a                	sd	s2,16(sp)
    8000305a:	e44e                	sd	s3,8(sp)
    8000305c:	e052                	sd	s4,0(sp)
    8000305e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003060:	00005597          	auipc	a1,0x5
    80003064:	49058593          	addi	a1,a1,1168 # 800084f0 <syscalls+0xc0>
    80003068:	00014517          	auipc	a0,0x14
    8000306c:	28050513          	addi	a0,a0,640 # 800172e8 <bcache>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	ad6080e7          	jalr	-1322(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003078:	0001c797          	auipc	a5,0x1c
    8000307c:	27078793          	addi	a5,a5,624 # 8001f2e8 <bcache+0x8000>
    80003080:	0001c717          	auipc	a4,0x1c
    80003084:	4d070713          	addi	a4,a4,1232 # 8001f550 <bcache+0x8268>
    80003088:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000308c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003090:	00014497          	auipc	s1,0x14
    80003094:	27048493          	addi	s1,s1,624 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80003098:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000309a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000309c:	00005a17          	auipc	s4,0x5
    800030a0:	45ca0a13          	addi	s4,s4,1116 # 800084f8 <syscalls+0xc8>
    b->next = bcache.head.next;
    800030a4:	2b893783          	ld	a5,696(s2)
    800030a8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030aa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030ae:	85d2                	mv	a1,s4
    800030b0:	01048513          	addi	a0,s1,16
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	4bc080e7          	jalr	1212(ra) # 80004570 <initsleeplock>
    bcache.head.next->prev = b;
    800030bc:	2b893783          	ld	a5,696(s2)
    800030c0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030c2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030c6:	45848493          	addi	s1,s1,1112
    800030ca:	fd349de3          	bne	s1,s3,800030a4 <binit+0x54>
  }
}
    800030ce:	70a2                	ld	ra,40(sp)
    800030d0:	7402                	ld	s0,32(sp)
    800030d2:	64e2                	ld	s1,24(sp)
    800030d4:	6942                	ld	s2,16(sp)
    800030d6:	69a2                	ld	s3,8(sp)
    800030d8:	6a02                	ld	s4,0(sp)
    800030da:	6145                	addi	sp,sp,48
    800030dc:	8082                	ret

00000000800030de <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030de:	7179                	addi	sp,sp,-48
    800030e0:	f406                	sd	ra,40(sp)
    800030e2:	f022                	sd	s0,32(sp)
    800030e4:	ec26                	sd	s1,24(sp)
    800030e6:	e84a                	sd	s2,16(sp)
    800030e8:	e44e                	sd	s3,8(sp)
    800030ea:	1800                	addi	s0,sp,48
    800030ec:	89aa                	mv	s3,a0
    800030ee:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030f0:	00014517          	auipc	a0,0x14
    800030f4:	1f850513          	addi	a0,a0,504 # 800172e8 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	ade080e7          	jalr	-1314(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003100:	0001c497          	auipc	s1,0x1c
    80003104:	4a04b483          	ld	s1,1184(s1) # 8001f5a0 <bcache+0x82b8>
    80003108:	0001c797          	auipc	a5,0x1c
    8000310c:	44878793          	addi	a5,a5,1096 # 8001f550 <bcache+0x8268>
    80003110:	02f48f63          	beq	s1,a5,8000314e <bread+0x70>
    80003114:	873e                	mv	a4,a5
    80003116:	a021                	j	8000311e <bread+0x40>
    80003118:	68a4                	ld	s1,80(s1)
    8000311a:	02e48a63          	beq	s1,a4,8000314e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000311e:	449c                	lw	a5,8(s1)
    80003120:	ff379ce3          	bne	a5,s3,80003118 <bread+0x3a>
    80003124:	44dc                	lw	a5,12(s1)
    80003126:	ff2799e3          	bne	a5,s2,80003118 <bread+0x3a>
      b->refcnt++;
    8000312a:	40bc                	lw	a5,64(s1)
    8000312c:	2785                	addiw	a5,a5,1
    8000312e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003130:	00014517          	auipc	a0,0x14
    80003134:	1b850513          	addi	a0,a0,440 # 800172e8 <bcache>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003140:	01048513          	addi	a0,s1,16
    80003144:	00001097          	auipc	ra,0x1
    80003148:	466080e7          	jalr	1126(ra) # 800045aa <acquiresleep>
      return b;
    8000314c:	a8b9                	j	800031aa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000314e:	0001c497          	auipc	s1,0x1c
    80003152:	44a4b483          	ld	s1,1098(s1) # 8001f598 <bcache+0x82b0>
    80003156:	0001c797          	auipc	a5,0x1c
    8000315a:	3fa78793          	addi	a5,a5,1018 # 8001f550 <bcache+0x8268>
    8000315e:	00f48863          	beq	s1,a5,8000316e <bread+0x90>
    80003162:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003164:	40bc                	lw	a5,64(s1)
    80003166:	cf81                	beqz	a5,8000317e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003168:	64a4                	ld	s1,72(s1)
    8000316a:	fee49de3          	bne	s1,a4,80003164 <bread+0x86>
  panic("bget: no buffers");
    8000316e:	00005517          	auipc	a0,0x5
    80003172:	39250513          	addi	a0,a0,914 # 80008500 <syscalls+0xd0>
    80003176:	ffffd097          	auipc	ra,0xffffd
    8000317a:	3ba080e7          	jalr	954(ra) # 80000530 <panic>
      b->dev = dev;
    8000317e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003182:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003186:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000318a:	4785                	li	a5,1
    8000318c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	15a50513          	addi	a0,a0,346 # 800172e8 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	af4080e7          	jalr	-1292(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000319e:	01048513          	addi	a0,s1,16
    800031a2:	00001097          	auipc	ra,0x1
    800031a6:	408080e7          	jalr	1032(ra) # 800045aa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031aa:	409c                	lw	a5,0(s1)
    800031ac:	cb89                	beqz	a5,800031be <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031ae:	8526                	mv	a0,s1
    800031b0:	70a2                	ld	ra,40(sp)
    800031b2:	7402                	ld	s0,32(sp)
    800031b4:	64e2                	ld	s1,24(sp)
    800031b6:	6942                	ld	s2,16(sp)
    800031b8:	69a2                	ld	s3,8(sp)
    800031ba:	6145                	addi	sp,sp,48
    800031bc:	8082                	ret
    virtio_disk_rw(b, 0);
    800031be:	4581                	li	a1,0
    800031c0:	8526                	mv	a0,s1
    800031c2:	00003097          	auipc	ra,0x3
    800031c6:	f14080e7          	jalr	-236(ra) # 800060d6 <virtio_disk_rw>
    b->valid = 1;
    800031ca:	4785                	li	a5,1
    800031cc:	c09c                	sw	a5,0(s1)
  return b;
    800031ce:	b7c5                	j	800031ae <bread+0xd0>

00000000800031d0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031d0:	1101                	addi	sp,sp,-32
    800031d2:	ec06                	sd	ra,24(sp)
    800031d4:	e822                	sd	s0,16(sp)
    800031d6:	e426                	sd	s1,8(sp)
    800031d8:	1000                	addi	s0,sp,32
    800031da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031dc:	0541                	addi	a0,a0,16
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	466080e7          	jalr	1126(ra) # 80004644 <holdingsleep>
    800031e6:	cd01                	beqz	a0,800031fe <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031e8:	4585                	li	a1,1
    800031ea:	8526                	mv	a0,s1
    800031ec:	00003097          	auipc	ra,0x3
    800031f0:	eea080e7          	jalr	-278(ra) # 800060d6 <virtio_disk_rw>
}
    800031f4:	60e2                	ld	ra,24(sp)
    800031f6:	6442                	ld	s0,16(sp)
    800031f8:	64a2                	ld	s1,8(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret
    panic("bwrite");
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	31a50513          	addi	a0,a0,794 # 80008518 <syscalls+0xe8>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	32a080e7          	jalr	810(ra) # 80000530 <panic>

000000008000320e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	e04a                	sd	s2,0(sp)
    80003218:	1000                	addi	s0,sp,32
    8000321a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000321c:	01050913          	addi	s2,a0,16
    80003220:	854a                	mv	a0,s2
    80003222:	00001097          	auipc	ra,0x1
    80003226:	422080e7          	jalr	1058(ra) # 80004644 <holdingsleep>
    8000322a:	c92d                	beqz	a0,8000329c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000322c:	854a                	mv	a0,s2
    8000322e:	00001097          	auipc	ra,0x1
    80003232:	3d2080e7          	jalr	978(ra) # 80004600 <releasesleep>

  acquire(&bcache.lock);
    80003236:	00014517          	auipc	a0,0x14
    8000323a:	0b250513          	addi	a0,a0,178 # 800172e8 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	998080e7          	jalr	-1640(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003246:	40bc                	lw	a5,64(s1)
    80003248:	37fd                	addiw	a5,a5,-1
    8000324a:	0007871b          	sext.w	a4,a5
    8000324e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003250:	eb05                	bnez	a4,80003280 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003252:	68bc                	ld	a5,80(s1)
    80003254:	64b8                	ld	a4,72(s1)
    80003256:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003258:	64bc                	ld	a5,72(s1)
    8000325a:	68b8                	ld	a4,80(s1)
    8000325c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000325e:	0001c797          	auipc	a5,0x1c
    80003262:	08a78793          	addi	a5,a5,138 # 8001f2e8 <bcache+0x8000>
    80003266:	2b87b703          	ld	a4,696(a5)
    8000326a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000326c:	0001c717          	auipc	a4,0x1c
    80003270:	2e470713          	addi	a4,a4,740 # 8001f550 <bcache+0x8268>
    80003274:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003276:	2b87b703          	ld	a4,696(a5)
    8000327a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000327c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003280:	00014517          	auipc	a0,0x14
    80003284:	06850513          	addi	a0,a0,104 # 800172e8 <bcache>
    80003288:	ffffe097          	auipc	ra,0xffffe
    8000328c:	a02080e7          	jalr	-1534(ra) # 80000c8a <release>
}
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	64a2                	ld	s1,8(sp)
    80003296:	6902                	ld	s2,0(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret
    panic("brelse");
    8000329c:	00005517          	auipc	a0,0x5
    800032a0:	28450513          	addi	a0,a0,644 # 80008520 <syscalls+0xf0>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	28c080e7          	jalr	652(ra) # 80000530 <panic>

00000000800032ac <bpin>:

void
bpin(struct buf *b) {
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	e426                	sd	s1,8(sp)
    800032b4:	1000                	addi	s0,sp,32
    800032b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b8:	00014517          	auipc	a0,0x14
    800032bc:	03050513          	addi	a0,a0,48 # 800172e8 <bcache>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	916080e7          	jalr	-1770(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800032c8:	40bc                	lw	a5,64(s1)
    800032ca:	2785                	addiw	a5,a5,1
    800032cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ce:	00014517          	auipc	a0,0x14
    800032d2:	01a50513          	addi	a0,a0,26 # 800172e8 <bcache>
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	9b4080e7          	jalr	-1612(ra) # 80000c8a <release>
}
    800032de:	60e2                	ld	ra,24(sp)
    800032e0:	6442                	ld	s0,16(sp)
    800032e2:	64a2                	ld	s1,8(sp)
    800032e4:	6105                	addi	sp,sp,32
    800032e6:	8082                	ret

00000000800032e8 <bunpin>:

void
bunpin(struct buf *b) {
    800032e8:	1101                	addi	sp,sp,-32
    800032ea:	ec06                	sd	ra,24(sp)
    800032ec:	e822                	sd	s0,16(sp)
    800032ee:	e426                	sd	s1,8(sp)
    800032f0:	1000                	addi	s0,sp,32
    800032f2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032f4:	00014517          	auipc	a0,0x14
    800032f8:	ff450513          	addi	a0,a0,-12 # 800172e8 <bcache>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003304:	40bc                	lw	a5,64(s1)
    80003306:	37fd                	addiw	a5,a5,-1
    80003308:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000330a:	00014517          	auipc	a0,0x14
    8000330e:	fde50513          	addi	a0,a0,-34 # 800172e8 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	978080e7          	jalr	-1672(ra) # 80000c8a <release>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6105                	addi	sp,sp,32
    80003322:	8082                	ret

0000000080003324 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003324:	1101                	addi	sp,sp,-32
    80003326:	ec06                	sd	ra,24(sp)
    80003328:	e822                	sd	s0,16(sp)
    8000332a:	e426                	sd	s1,8(sp)
    8000332c:	e04a                	sd	s2,0(sp)
    8000332e:	1000                	addi	s0,sp,32
    80003330:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003332:	00d5d59b          	srliw	a1,a1,0xd
    80003336:	0001c797          	auipc	a5,0x1c
    8000333a:	68e7a783          	lw	a5,1678(a5) # 8001f9c4 <sb+0x1c>
    8000333e:	9dbd                	addw	a1,a1,a5
    80003340:	00000097          	auipc	ra,0x0
    80003344:	d9e080e7          	jalr	-610(ra) # 800030de <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003348:	0074f713          	andi	a4,s1,7
    8000334c:	4785                	li	a5,1
    8000334e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003352:	14ce                	slli	s1,s1,0x33
    80003354:	90d9                	srli	s1,s1,0x36
    80003356:	00950733          	add	a4,a0,s1
    8000335a:	05874703          	lbu	a4,88(a4)
    8000335e:	00e7f6b3          	and	a3,a5,a4
    80003362:	c69d                	beqz	a3,80003390 <bfree+0x6c>
    80003364:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003366:	94aa                	add	s1,s1,a0
    80003368:	fff7c793          	not	a5,a5
    8000336c:	8ff9                	and	a5,a5,a4
    8000336e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003372:	00001097          	auipc	ra,0x1
    80003376:	118080e7          	jalr	280(ra) # 8000448a <log_write>
  brelse(bp);
    8000337a:	854a                	mv	a0,s2
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	e92080e7          	jalr	-366(ra) # 8000320e <brelse>
}
    80003384:	60e2                	ld	ra,24(sp)
    80003386:	6442                	ld	s0,16(sp)
    80003388:	64a2                	ld	s1,8(sp)
    8000338a:	6902                	ld	s2,0(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("freeing free block");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	19850513          	addi	a0,a0,408 # 80008528 <syscalls+0xf8>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	198080e7          	jalr	408(ra) # 80000530 <panic>

00000000800033a0 <balloc>:
{
    800033a0:	711d                	addi	sp,sp,-96
    800033a2:	ec86                	sd	ra,88(sp)
    800033a4:	e8a2                	sd	s0,80(sp)
    800033a6:	e4a6                	sd	s1,72(sp)
    800033a8:	e0ca                	sd	s2,64(sp)
    800033aa:	fc4e                	sd	s3,56(sp)
    800033ac:	f852                	sd	s4,48(sp)
    800033ae:	f456                	sd	s5,40(sp)
    800033b0:	f05a                	sd	s6,32(sp)
    800033b2:	ec5e                	sd	s7,24(sp)
    800033b4:	e862                	sd	s8,16(sp)
    800033b6:	e466                	sd	s9,8(sp)
    800033b8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033ba:	0001c797          	auipc	a5,0x1c
    800033be:	5f27a783          	lw	a5,1522(a5) # 8001f9ac <sb+0x4>
    800033c2:	cbd1                	beqz	a5,80003456 <balloc+0xb6>
    800033c4:	8baa                	mv	s7,a0
    800033c6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033c8:	0001cb17          	auipc	s6,0x1c
    800033cc:	5e0b0b13          	addi	s6,s6,1504 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033d2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033d6:	6c89                	lui	s9,0x2
    800033d8:	a831                	j	800033f4 <balloc+0x54>
    brelse(bp);
    800033da:	854a                	mv	a0,s2
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	e32080e7          	jalr	-462(ra) # 8000320e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033e4:	015c87bb          	addw	a5,s9,s5
    800033e8:	00078a9b          	sext.w	s5,a5
    800033ec:	004b2703          	lw	a4,4(s6)
    800033f0:	06eaf363          	bgeu	s5,a4,80003456 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033f4:	41fad79b          	sraiw	a5,s5,0x1f
    800033f8:	0137d79b          	srliw	a5,a5,0x13
    800033fc:	015787bb          	addw	a5,a5,s5
    80003400:	40d7d79b          	sraiw	a5,a5,0xd
    80003404:	01cb2583          	lw	a1,28(s6)
    80003408:	9dbd                	addw	a1,a1,a5
    8000340a:	855e                	mv	a0,s7
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	cd2080e7          	jalr	-814(ra) # 800030de <bread>
    80003414:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003416:	004b2503          	lw	a0,4(s6)
    8000341a:	000a849b          	sext.w	s1,s5
    8000341e:	8662                	mv	a2,s8
    80003420:	faa4fde3          	bgeu	s1,a0,800033da <balloc+0x3a>
      m = 1 << (bi % 8);
    80003424:	41f6579b          	sraiw	a5,a2,0x1f
    80003428:	01d7d69b          	srliw	a3,a5,0x1d
    8000342c:	00c6873b          	addw	a4,a3,a2
    80003430:	00777793          	andi	a5,a4,7
    80003434:	9f95                	subw	a5,a5,a3
    80003436:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000343a:	4037571b          	sraiw	a4,a4,0x3
    8000343e:	00e906b3          	add	a3,s2,a4
    80003442:	0586c683          	lbu	a3,88(a3)
    80003446:	00d7f5b3          	and	a1,a5,a3
    8000344a:	cd91                	beqz	a1,80003466 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000344c:	2605                	addiw	a2,a2,1
    8000344e:	2485                	addiw	s1,s1,1
    80003450:	fd4618e3          	bne	a2,s4,80003420 <balloc+0x80>
    80003454:	b759                	j	800033da <balloc+0x3a>
  panic("balloc: out of blocks");
    80003456:	00005517          	auipc	a0,0x5
    8000345a:	0ea50513          	addi	a0,a0,234 # 80008540 <syscalls+0x110>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	0d2080e7          	jalr	210(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003466:	974a                	add	a4,a4,s2
    80003468:	8fd5                	or	a5,a5,a3
    8000346a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00001097          	auipc	ra,0x1
    80003474:	01a080e7          	jalr	26(ra) # 8000448a <log_write>
        brelse(bp);
    80003478:	854a                	mv	a0,s2
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	d94080e7          	jalr	-620(ra) # 8000320e <brelse>
  bp = bread(dev, bno);
    80003482:	85a6                	mv	a1,s1
    80003484:	855e                	mv	a0,s7
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	c58080e7          	jalr	-936(ra) # 800030de <bread>
    8000348e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003490:	40000613          	li	a2,1024
    80003494:	4581                	li	a1,0
    80003496:	05850513          	addi	a0,a0,88
    8000349a:	ffffe097          	auipc	ra,0xffffe
    8000349e:	838080e7          	jalr	-1992(ra) # 80000cd2 <memset>
  log_write(bp);
    800034a2:	854a                	mv	a0,s2
    800034a4:	00001097          	auipc	ra,0x1
    800034a8:	fe6080e7          	jalr	-26(ra) # 8000448a <log_write>
  brelse(bp);
    800034ac:	854a                	mv	a0,s2
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	d60080e7          	jalr	-672(ra) # 8000320e <brelse>
}
    800034b6:	8526                	mv	a0,s1
    800034b8:	60e6                	ld	ra,88(sp)
    800034ba:	6446                	ld	s0,80(sp)
    800034bc:	64a6                	ld	s1,72(sp)
    800034be:	6906                	ld	s2,64(sp)
    800034c0:	79e2                	ld	s3,56(sp)
    800034c2:	7a42                	ld	s4,48(sp)
    800034c4:	7aa2                	ld	s5,40(sp)
    800034c6:	7b02                	ld	s6,32(sp)
    800034c8:	6be2                	ld	s7,24(sp)
    800034ca:	6c42                	ld	s8,16(sp)
    800034cc:	6ca2                	ld	s9,8(sp)
    800034ce:	6125                	addi	sp,sp,96
    800034d0:	8082                	ret

00000000800034d2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034d2:	7179                	addi	sp,sp,-48
    800034d4:	f406                	sd	ra,40(sp)
    800034d6:	f022                	sd	s0,32(sp)
    800034d8:	ec26                	sd	s1,24(sp)
    800034da:	e84a                	sd	s2,16(sp)
    800034dc:	e44e                	sd	s3,8(sp)
    800034de:	e052                	sd	s4,0(sp)
    800034e0:	1800                	addi	s0,sp,48
    800034e2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034e4:	47ad                	li	a5,11
    800034e6:	04b7fe63          	bgeu	a5,a1,80003542 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034ea:	ff45849b          	addiw	s1,a1,-12
    800034ee:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034f2:	0ff00793          	li	a5,255
    800034f6:	0ae7e363          	bltu	a5,a4,8000359c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034fa:	08052583          	lw	a1,128(a0)
    800034fe:	c5ad                	beqz	a1,80003568 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003500:	00092503          	lw	a0,0(s2)
    80003504:	00000097          	auipc	ra,0x0
    80003508:	bda080e7          	jalr	-1062(ra) # 800030de <bread>
    8000350c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000350e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003512:	02049593          	slli	a1,s1,0x20
    80003516:	9181                	srli	a1,a1,0x20
    80003518:	058a                	slli	a1,a1,0x2
    8000351a:	00b784b3          	add	s1,a5,a1
    8000351e:	0004a983          	lw	s3,0(s1)
    80003522:	04098d63          	beqz	s3,8000357c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003526:	8552                	mv	a0,s4
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	ce6080e7          	jalr	-794(ra) # 8000320e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003530:	854e                	mv	a0,s3
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6a02                	ld	s4,0(sp)
    8000353e:	6145                	addi	sp,sp,48
    80003540:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003542:	02059493          	slli	s1,a1,0x20
    80003546:	9081                	srli	s1,s1,0x20
    80003548:	048a                	slli	s1,s1,0x2
    8000354a:	94aa                	add	s1,s1,a0
    8000354c:	0504a983          	lw	s3,80(s1)
    80003550:	fe0990e3          	bnez	s3,80003530 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003554:	4108                	lw	a0,0(a0)
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	e4a080e7          	jalr	-438(ra) # 800033a0 <balloc>
    8000355e:	0005099b          	sext.w	s3,a0
    80003562:	0534a823          	sw	s3,80(s1)
    80003566:	b7e9                	j	80003530 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003568:	4108                	lw	a0,0(a0)
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	e36080e7          	jalr	-458(ra) # 800033a0 <balloc>
    80003572:	0005059b          	sext.w	a1,a0
    80003576:	08b92023          	sw	a1,128(s2)
    8000357a:	b759                	j	80003500 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000357c:	00092503          	lw	a0,0(s2)
    80003580:	00000097          	auipc	ra,0x0
    80003584:	e20080e7          	jalr	-480(ra) # 800033a0 <balloc>
    80003588:	0005099b          	sext.w	s3,a0
    8000358c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003590:	8552                	mv	a0,s4
    80003592:	00001097          	auipc	ra,0x1
    80003596:	ef8080e7          	jalr	-264(ra) # 8000448a <log_write>
    8000359a:	b771                	j	80003526 <bmap+0x54>
  panic("bmap: out of range");
    8000359c:	00005517          	auipc	a0,0x5
    800035a0:	fbc50513          	addi	a0,a0,-68 # 80008558 <syscalls+0x128>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	f8c080e7          	jalr	-116(ra) # 80000530 <panic>

00000000800035ac <iget>:
{
    800035ac:	7179                	addi	sp,sp,-48
    800035ae:	f406                	sd	ra,40(sp)
    800035b0:	f022                	sd	s0,32(sp)
    800035b2:	ec26                	sd	s1,24(sp)
    800035b4:	e84a                	sd	s2,16(sp)
    800035b6:	e44e                	sd	s3,8(sp)
    800035b8:	e052                	sd	s4,0(sp)
    800035ba:	1800                	addi	s0,sp,48
    800035bc:	89aa                	mv	s3,a0
    800035be:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035c0:	0001c517          	auipc	a0,0x1c
    800035c4:	40850513          	addi	a0,a0,1032 # 8001f9c8 <itable>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	60e080e7          	jalr	1550(ra) # 80000bd6 <acquire>
  empty = 0;
    800035d0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d2:	0001c497          	auipc	s1,0x1c
    800035d6:	40e48493          	addi	s1,s1,1038 # 8001f9e0 <itable+0x18>
    800035da:	0001e697          	auipc	a3,0x1e
    800035de:	e9668693          	addi	a3,a3,-362 # 80021470 <log>
    800035e2:	a039                	j	800035f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e4:	02090b63          	beqz	s2,8000361a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e8:	08848493          	addi	s1,s1,136
    800035ec:	02d48a63          	beq	s1,a3,80003620 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035f0:	449c                	lw	a5,8(s1)
    800035f2:	fef059e3          	blez	a5,800035e4 <iget+0x38>
    800035f6:	4098                	lw	a4,0(s1)
    800035f8:	ff3716e3          	bne	a4,s3,800035e4 <iget+0x38>
    800035fc:	40d8                	lw	a4,4(s1)
    800035fe:	ff4713e3          	bne	a4,s4,800035e4 <iget+0x38>
      ip->ref++;
    80003602:	2785                	addiw	a5,a5,1
    80003604:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003606:	0001c517          	auipc	a0,0x1c
    8000360a:	3c250513          	addi	a0,a0,962 # 8001f9c8 <itable>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	67c080e7          	jalr	1660(ra) # 80000c8a <release>
      return ip;
    80003616:	8926                	mv	s2,s1
    80003618:	a03d                	j	80003646 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000361a:	f7f9                	bnez	a5,800035e8 <iget+0x3c>
    8000361c:	8926                	mv	s2,s1
    8000361e:	b7e9                	j	800035e8 <iget+0x3c>
  if(empty == 0)
    80003620:	02090c63          	beqz	s2,80003658 <iget+0xac>
  ip->dev = dev;
    80003624:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003628:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000362c:	4785                	li	a5,1
    8000362e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003632:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003636:	0001c517          	auipc	a0,0x1c
    8000363a:	39250513          	addi	a0,a0,914 # 8001f9c8 <itable>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	64c080e7          	jalr	1612(ra) # 80000c8a <release>
}
    80003646:	854a                	mv	a0,s2
    80003648:	70a2                	ld	ra,40(sp)
    8000364a:	7402                	ld	s0,32(sp)
    8000364c:	64e2                	ld	s1,24(sp)
    8000364e:	6942                	ld	s2,16(sp)
    80003650:	69a2                	ld	s3,8(sp)
    80003652:	6a02                	ld	s4,0(sp)
    80003654:	6145                	addi	sp,sp,48
    80003656:	8082                	ret
    panic("iget: no inodes");
    80003658:	00005517          	auipc	a0,0x5
    8000365c:	f1850513          	addi	a0,a0,-232 # 80008570 <syscalls+0x140>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	ed0080e7          	jalr	-304(ra) # 80000530 <panic>

0000000080003668 <fsinit>:
fsinit(int dev) {
    80003668:	7179                	addi	sp,sp,-48
    8000366a:	f406                	sd	ra,40(sp)
    8000366c:	f022                	sd	s0,32(sp)
    8000366e:	ec26                	sd	s1,24(sp)
    80003670:	e84a                	sd	s2,16(sp)
    80003672:	e44e                	sd	s3,8(sp)
    80003674:	1800                	addi	s0,sp,48
    80003676:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003678:	4585                	li	a1,1
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	a64080e7          	jalr	-1436(ra) # 800030de <bread>
    80003682:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003684:	0001c997          	auipc	s3,0x1c
    80003688:	32498993          	addi	s3,s3,804 # 8001f9a8 <sb>
    8000368c:	02000613          	li	a2,32
    80003690:	05850593          	addi	a1,a0,88
    80003694:	854e                	mv	a0,s3
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	69c080e7          	jalr	1692(ra) # 80000d32 <memmove>
  brelse(bp);
    8000369e:	8526                	mv	a0,s1
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	b6e080e7          	jalr	-1170(ra) # 8000320e <brelse>
  if(sb.magic != FSMAGIC)
    800036a8:	0009a703          	lw	a4,0(s3)
    800036ac:	102037b7          	lui	a5,0x10203
    800036b0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036b4:	02f71263          	bne	a4,a5,800036d8 <fsinit+0x70>
  initlog(dev, &sb);
    800036b8:	0001c597          	auipc	a1,0x1c
    800036bc:	2f058593          	addi	a1,a1,752 # 8001f9a8 <sb>
    800036c0:	854a                	mv	a0,s2
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	b4c080e7          	jalr	-1204(ra) # 8000420e <initlog>
}
    800036ca:	70a2                	ld	ra,40(sp)
    800036cc:	7402                	ld	s0,32(sp)
    800036ce:	64e2                	ld	s1,24(sp)
    800036d0:	6942                	ld	s2,16(sp)
    800036d2:	69a2                	ld	s3,8(sp)
    800036d4:	6145                	addi	sp,sp,48
    800036d6:	8082                	ret
    panic("invalid file system");
    800036d8:	00005517          	auipc	a0,0x5
    800036dc:	ea850513          	addi	a0,a0,-344 # 80008580 <syscalls+0x150>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	e50080e7          	jalr	-432(ra) # 80000530 <panic>

00000000800036e8 <iinit>:
{
    800036e8:	7179                	addi	sp,sp,-48
    800036ea:	f406                	sd	ra,40(sp)
    800036ec:	f022                	sd	s0,32(sp)
    800036ee:	ec26                	sd	s1,24(sp)
    800036f0:	e84a                	sd	s2,16(sp)
    800036f2:	e44e                	sd	s3,8(sp)
    800036f4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036f6:	00005597          	auipc	a1,0x5
    800036fa:	ea258593          	addi	a1,a1,-350 # 80008598 <syscalls+0x168>
    800036fe:	0001c517          	auipc	a0,0x1c
    80003702:	2ca50513          	addi	a0,a0,714 # 8001f9c8 <itable>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	440080e7          	jalr	1088(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000370e:	0001c497          	auipc	s1,0x1c
    80003712:	2e248493          	addi	s1,s1,738 # 8001f9f0 <itable+0x28>
    80003716:	0001e997          	auipc	s3,0x1e
    8000371a:	d6a98993          	addi	s3,s3,-662 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000371e:	00005917          	auipc	s2,0x5
    80003722:	e8290913          	addi	s2,s2,-382 # 800085a0 <syscalls+0x170>
    80003726:	85ca                	mv	a1,s2
    80003728:	8526                	mv	a0,s1
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	e46080e7          	jalr	-442(ra) # 80004570 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003732:	08848493          	addi	s1,s1,136
    80003736:	ff3498e3          	bne	s1,s3,80003726 <iinit+0x3e>
}
    8000373a:	70a2                	ld	ra,40(sp)
    8000373c:	7402                	ld	s0,32(sp)
    8000373e:	64e2                	ld	s1,24(sp)
    80003740:	6942                	ld	s2,16(sp)
    80003742:	69a2                	ld	s3,8(sp)
    80003744:	6145                	addi	sp,sp,48
    80003746:	8082                	ret

0000000080003748 <ialloc>:
{
    80003748:	715d                	addi	sp,sp,-80
    8000374a:	e486                	sd	ra,72(sp)
    8000374c:	e0a2                	sd	s0,64(sp)
    8000374e:	fc26                	sd	s1,56(sp)
    80003750:	f84a                	sd	s2,48(sp)
    80003752:	f44e                	sd	s3,40(sp)
    80003754:	f052                	sd	s4,32(sp)
    80003756:	ec56                	sd	s5,24(sp)
    80003758:	e85a                	sd	s6,16(sp)
    8000375a:	e45e                	sd	s7,8(sp)
    8000375c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000375e:	0001c717          	auipc	a4,0x1c
    80003762:	25672703          	lw	a4,598(a4) # 8001f9b4 <sb+0xc>
    80003766:	4785                	li	a5,1
    80003768:	04e7fa63          	bgeu	a5,a4,800037bc <ialloc+0x74>
    8000376c:	8aaa                	mv	s5,a0
    8000376e:	8bae                	mv	s7,a1
    80003770:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003772:	0001ca17          	auipc	s4,0x1c
    80003776:	236a0a13          	addi	s4,s4,566 # 8001f9a8 <sb>
    8000377a:	00048b1b          	sext.w	s6,s1
    8000377e:	0044d593          	srli	a1,s1,0x4
    80003782:	018a2783          	lw	a5,24(s4)
    80003786:	9dbd                	addw	a1,a1,a5
    80003788:	8556                	mv	a0,s5
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	954080e7          	jalr	-1708(ra) # 800030de <bread>
    80003792:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003794:	05850993          	addi	s3,a0,88
    80003798:	00f4f793          	andi	a5,s1,15
    8000379c:	079a                	slli	a5,a5,0x6
    8000379e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037a0:	00099783          	lh	a5,0(s3)
    800037a4:	c785                	beqz	a5,800037cc <ialloc+0x84>
    brelse(bp);
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	a68080e7          	jalr	-1432(ra) # 8000320e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ae:	0485                	addi	s1,s1,1
    800037b0:	00ca2703          	lw	a4,12(s4)
    800037b4:	0004879b          	sext.w	a5,s1
    800037b8:	fce7e1e3          	bltu	a5,a4,8000377a <ialloc+0x32>
  panic("ialloc: no inodes");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	dec50513          	addi	a0,a0,-532 # 800085a8 <syscalls+0x178>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d6c080e7          	jalr	-660(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800037cc:	04000613          	li	a2,64
    800037d0:	4581                	li	a1,0
    800037d2:	854e                	mv	a0,s3
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	4fe080e7          	jalr	1278(ra) # 80000cd2 <memset>
      dip->type = type;
    800037dc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037e0:	854a                	mv	a0,s2
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	ca8080e7          	jalr	-856(ra) # 8000448a <log_write>
      brelse(bp);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	a22080e7          	jalr	-1502(ra) # 8000320e <brelse>
      return iget(dev, inum);
    800037f4:	85da                	mv	a1,s6
    800037f6:	8556                	mv	a0,s5
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	db4080e7          	jalr	-588(ra) # 800035ac <iget>
}
    80003800:	60a6                	ld	ra,72(sp)
    80003802:	6406                	ld	s0,64(sp)
    80003804:	74e2                	ld	s1,56(sp)
    80003806:	7942                	ld	s2,48(sp)
    80003808:	79a2                	ld	s3,40(sp)
    8000380a:	7a02                	ld	s4,32(sp)
    8000380c:	6ae2                	ld	s5,24(sp)
    8000380e:	6b42                	ld	s6,16(sp)
    80003810:	6ba2                	ld	s7,8(sp)
    80003812:	6161                	addi	sp,sp,80
    80003814:	8082                	ret

0000000080003816 <iupdate>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	e04a                	sd	s2,0(sp)
    80003820:	1000                	addi	s0,sp,32
    80003822:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003824:	415c                	lw	a5,4(a0)
    80003826:	0047d79b          	srliw	a5,a5,0x4
    8000382a:	0001c597          	auipc	a1,0x1c
    8000382e:	1965a583          	lw	a1,406(a1) # 8001f9c0 <sb+0x18>
    80003832:	9dbd                	addw	a1,a1,a5
    80003834:	4108                	lw	a0,0(a0)
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	8a8080e7          	jalr	-1880(ra) # 800030de <bread>
    8000383e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003840:	05850793          	addi	a5,a0,88
    80003844:	40c8                	lw	a0,4(s1)
    80003846:	893d                	andi	a0,a0,15
    80003848:	051a                	slli	a0,a0,0x6
    8000384a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000384c:	04449703          	lh	a4,68(s1)
    80003850:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003854:	04649703          	lh	a4,70(s1)
    80003858:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000385c:	04849703          	lh	a4,72(s1)
    80003860:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003864:	04a49703          	lh	a4,74(s1)
    80003868:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000386c:	44f8                	lw	a4,76(s1)
    8000386e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003870:	03400613          	li	a2,52
    80003874:	05048593          	addi	a1,s1,80
    80003878:	0531                	addi	a0,a0,12
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	4b8080e7          	jalr	1208(ra) # 80000d32 <memmove>
  log_write(bp);
    80003882:	854a                	mv	a0,s2
    80003884:	00001097          	auipc	ra,0x1
    80003888:	c06080e7          	jalr	-1018(ra) # 8000448a <log_write>
  brelse(bp);
    8000388c:	854a                	mv	a0,s2
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	980080e7          	jalr	-1664(ra) # 8000320e <brelse>
}
    80003896:	60e2                	ld	ra,24(sp)
    80003898:	6442                	ld	s0,16(sp)
    8000389a:	64a2                	ld	s1,8(sp)
    8000389c:	6902                	ld	s2,0(sp)
    8000389e:	6105                	addi	sp,sp,32
    800038a0:	8082                	ret

00000000800038a2 <idup>:
{
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ae:	0001c517          	auipc	a0,0x1c
    800038b2:	11a50513          	addi	a0,a0,282 # 8001f9c8 <itable>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	320080e7          	jalr	800(ra) # 80000bd6 <acquire>
  ip->ref++;
    800038be:	449c                	lw	a5,8(s1)
    800038c0:	2785                	addiw	a5,a5,1
    800038c2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038c4:	0001c517          	auipc	a0,0x1c
    800038c8:	10450513          	addi	a0,a0,260 # 8001f9c8 <itable>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	3be080e7          	jalr	958(ra) # 80000c8a <release>
}
    800038d4:	8526                	mv	a0,s1
    800038d6:	60e2                	ld	ra,24(sp)
    800038d8:	6442                	ld	s0,16(sp)
    800038da:	64a2                	ld	s1,8(sp)
    800038dc:	6105                	addi	sp,sp,32
    800038de:	8082                	ret

00000000800038e0 <ilock>:
{
    800038e0:	1101                	addi	sp,sp,-32
    800038e2:	ec06                	sd	ra,24(sp)
    800038e4:	e822                	sd	s0,16(sp)
    800038e6:	e426                	sd	s1,8(sp)
    800038e8:	e04a                	sd	s2,0(sp)
    800038ea:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ec:	c115                	beqz	a0,80003910 <ilock+0x30>
    800038ee:	84aa                	mv	s1,a0
    800038f0:	451c                	lw	a5,8(a0)
    800038f2:	00f05f63          	blez	a5,80003910 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038f6:	0541                	addi	a0,a0,16
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	cb2080e7          	jalr	-846(ra) # 800045aa <acquiresleep>
  if(ip->valid == 0){
    80003900:	40bc                	lw	a5,64(s1)
    80003902:	cf99                	beqz	a5,80003920 <ilock+0x40>
}
    80003904:	60e2                	ld	ra,24(sp)
    80003906:	6442                	ld	s0,16(sp)
    80003908:	64a2                	ld	s1,8(sp)
    8000390a:	6902                	ld	s2,0(sp)
    8000390c:	6105                	addi	sp,sp,32
    8000390e:	8082                	ret
    panic("ilock");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	cb050513          	addi	a0,a0,-848 # 800085c0 <syscalls+0x190>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c18080e7          	jalr	-1000(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003920:	40dc                	lw	a5,4(s1)
    80003922:	0047d79b          	srliw	a5,a5,0x4
    80003926:	0001c597          	auipc	a1,0x1c
    8000392a:	09a5a583          	lw	a1,154(a1) # 8001f9c0 <sb+0x18>
    8000392e:	9dbd                	addw	a1,a1,a5
    80003930:	4088                	lw	a0,0(s1)
    80003932:	fffff097          	auipc	ra,0xfffff
    80003936:	7ac080e7          	jalr	1964(ra) # 800030de <bread>
    8000393a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000393c:	05850593          	addi	a1,a0,88
    80003940:	40dc                	lw	a5,4(s1)
    80003942:	8bbd                	andi	a5,a5,15
    80003944:	079a                	slli	a5,a5,0x6
    80003946:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003948:	00059783          	lh	a5,0(a1)
    8000394c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003950:	00259783          	lh	a5,2(a1)
    80003954:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003958:	00459783          	lh	a5,4(a1)
    8000395c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003960:	00659783          	lh	a5,6(a1)
    80003964:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003968:	459c                	lw	a5,8(a1)
    8000396a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000396c:	03400613          	li	a2,52
    80003970:	05b1                	addi	a1,a1,12
    80003972:	05048513          	addi	a0,s1,80
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	3bc080e7          	jalr	956(ra) # 80000d32 <memmove>
    brelse(bp);
    8000397e:	854a                	mv	a0,s2
    80003980:	00000097          	auipc	ra,0x0
    80003984:	88e080e7          	jalr	-1906(ra) # 8000320e <brelse>
    ip->valid = 1;
    80003988:	4785                	li	a5,1
    8000398a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000398c:	04449783          	lh	a5,68(s1)
    80003990:	fbb5                	bnez	a5,80003904 <ilock+0x24>
      panic("ilock: no type");
    80003992:	00005517          	auipc	a0,0x5
    80003996:	c3650513          	addi	a0,a0,-970 # 800085c8 <syscalls+0x198>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	b96080e7          	jalr	-1130(ra) # 80000530 <panic>

00000000800039a2 <iunlock>:
{
    800039a2:	1101                	addi	sp,sp,-32
    800039a4:	ec06                	sd	ra,24(sp)
    800039a6:	e822                	sd	s0,16(sp)
    800039a8:	e426                	sd	s1,8(sp)
    800039aa:	e04a                	sd	s2,0(sp)
    800039ac:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ae:	c905                	beqz	a0,800039de <iunlock+0x3c>
    800039b0:	84aa                	mv	s1,a0
    800039b2:	01050913          	addi	s2,a0,16
    800039b6:	854a                	mv	a0,s2
    800039b8:	00001097          	auipc	ra,0x1
    800039bc:	c8c080e7          	jalr	-884(ra) # 80004644 <holdingsleep>
    800039c0:	cd19                	beqz	a0,800039de <iunlock+0x3c>
    800039c2:	449c                	lw	a5,8(s1)
    800039c4:	00f05d63          	blez	a5,800039de <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039c8:	854a                	mv	a0,s2
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	c36080e7          	jalr	-970(ra) # 80004600 <releasesleep>
}
    800039d2:	60e2                	ld	ra,24(sp)
    800039d4:	6442                	ld	s0,16(sp)
    800039d6:	64a2                	ld	s1,8(sp)
    800039d8:	6902                	ld	s2,0(sp)
    800039da:	6105                	addi	sp,sp,32
    800039dc:	8082                	ret
    panic("iunlock");
    800039de:	00005517          	auipc	a0,0x5
    800039e2:	bfa50513          	addi	a0,a0,-1030 # 800085d8 <syscalls+0x1a8>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	b4a080e7          	jalr	-1206(ra) # 80000530 <panic>

00000000800039ee <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ee:	7179                	addi	sp,sp,-48
    800039f0:	f406                	sd	ra,40(sp)
    800039f2:	f022                	sd	s0,32(sp)
    800039f4:	ec26                	sd	s1,24(sp)
    800039f6:	e84a                	sd	s2,16(sp)
    800039f8:	e44e                	sd	s3,8(sp)
    800039fa:	e052                	sd	s4,0(sp)
    800039fc:	1800                	addi	s0,sp,48
    800039fe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a00:	05050493          	addi	s1,a0,80
    80003a04:	08050913          	addi	s2,a0,128
    80003a08:	a021                	j	80003a10 <itrunc+0x22>
    80003a0a:	0491                	addi	s1,s1,4
    80003a0c:	01248d63          	beq	s1,s2,80003a26 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a10:	408c                	lw	a1,0(s1)
    80003a12:	dde5                	beqz	a1,80003a0a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a14:	0009a503          	lw	a0,0(s3)
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	90c080e7          	jalr	-1780(ra) # 80003324 <bfree>
      ip->addrs[i] = 0;
    80003a20:	0004a023          	sw	zero,0(s1)
    80003a24:	b7dd                	j	80003a0a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a26:	0809a583          	lw	a1,128(s3)
    80003a2a:	e185                	bnez	a1,80003a4a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a2c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a30:	854e                	mv	a0,s3
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	de4080e7          	jalr	-540(ra) # 80003816 <iupdate>
}
    80003a3a:	70a2                	ld	ra,40(sp)
    80003a3c:	7402                	ld	s0,32(sp)
    80003a3e:	64e2                	ld	s1,24(sp)
    80003a40:	6942                	ld	s2,16(sp)
    80003a42:	69a2                	ld	s3,8(sp)
    80003a44:	6a02                	ld	s4,0(sp)
    80003a46:	6145                	addi	sp,sp,48
    80003a48:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a4a:	0009a503          	lw	a0,0(s3)
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	690080e7          	jalr	1680(ra) # 800030de <bread>
    80003a56:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a58:	05850493          	addi	s1,a0,88
    80003a5c:	45850913          	addi	s2,a0,1112
    80003a60:	a811                	j	80003a74 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a62:	0009a503          	lw	a0,0(s3)
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	8be080e7          	jalr	-1858(ra) # 80003324 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a6e:	0491                	addi	s1,s1,4
    80003a70:	01248563          	beq	s1,s2,80003a7a <itrunc+0x8c>
      if(a[j])
    80003a74:	408c                	lw	a1,0(s1)
    80003a76:	dde5                	beqz	a1,80003a6e <itrunc+0x80>
    80003a78:	b7ed                	j	80003a62 <itrunc+0x74>
    brelse(bp);
    80003a7a:	8552                	mv	a0,s4
    80003a7c:	fffff097          	auipc	ra,0xfffff
    80003a80:	792080e7          	jalr	1938(ra) # 8000320e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a84:	0809a583          	lw	a1,128(s3)
    80003a88:	0009a503          	lw	a0,0(s3)
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	898080e7          	jalr	-1896(ra) # 80003324 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a94:	0809a023          	sw	zero,128(s3)
    80003a98:	bf51                	j	80003a2c <itrunc+0x3e>

0000000080003a9a <iput>:
{
    80003a9a:	1101                	addi	sp,sp,-32
    80003a9c:	ec06                	sd	ra,24(sp)
    80003a9e:	e822                	sd	s0,16(sp)
    80003aa0:	e426                	sd	s1,8(sp)
    80003aa2:	e04a                	sd	s2,0(sp)
    80003aa4:	1000                	addi	s0,sp,32
    80003aa6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa8:	0001c517          	auipc	a0,0x1c
    80003aac:	f2050513          	addi	a0,a0,-224 # 8001f9c8 <itable>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	126080e7          	jalr	294(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab8:	4498                	lw	a4,8(s1)
    80003aba:	4785                	li	a5,1
    80003abc:	02f70363          	beq	a4,a5,80003ae2 <iput+0x48>
  ip->ref--;
    80003ac0:	449c                	lw	a5,8(s1)
    80003ac2:	37fd                	addiw	a5,a5,-1
    80003ac4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ac6:	0001c517          	auipc	a0,0x1c
    80003aca:	f0250513          	addi	a0,a0,-254 # 8001f9c8 <itable>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	1bc080e7          	jalr	444(ra) # 80000c8a <release>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	64a2                	ld	s1,8(sp)
    80003adc:	6902                	ld	s2,0(sp)
    80003ade:	6105                	addi	sp,sp,32
    80003ae0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae2:	40bc                	lw	a5,64(s1)
    80003ae4:	dff1                	beqz	a5,80003ac0 <iput+0x26>
    80003ae6:	04a49783          	lh	a5,74(s1)
    80003aea:	fbf9                	bnez	a5,80003ac0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003aec:	01048913          	addi	s2,s1,16
    80003af0:	854a                	mv	a0,s2
    80003af2:	00001097          	auipc	ra,0x1
    80003af6:	ab8080e7          	jalr	-1352(ra) # 800045aa <acquiresleep>
    release(&itable.lock);
    80003afa:	0001c517          	auipc	a0,0x1c
    80003afe:	ece50513          	addi	a0,a0,-306 # 8001f9c8 <itable>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	188080e7          	jalr	392(ra) # 80000c8a <release>
    itrunc(ip);
    80003b0a:	8526                	mv	a0,s1
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	ee2080e7          	jalr	-286(ra) # 800039ee <itrunc>
    ip->type = 0;
    80003b14:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b18:	8526                	mv	a0,s1
    80003b1a:	00000097          	auipc	ra,0x0
    80003b1e:	cfc080e7          	jalr	-772(ra) # 80003816 <iupdate>
    ip->valid = 0;
    80003b22:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b26:	854a                	mv	a0,s2
    80003b28:	00001097          	auipc	ra,0x1
    80003b2c:	ad8080e7          	jalr	-1320(ra) # 80004600 <releasesleep>
    acquire(&itable.lock);
    80003b30:	0001c517          	auipc	a0,0x1c
    80003b34:	e9850513          	addi	a0,a0,-360 # 8001f9c8 <itable>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	09e080e7          	jalr	158(ra) # 80000bd6 <acquire>
    80003b40:	b741                	j	80003ac0 <iput+0x26>

0000000080003b42 <iunlockput>:
{
    80003b42:	1101                	addi	sp,sp,-32
    80003b44:	ec06                	sd	ra,24(sp)
    80003b46:	e822                	sd	s0,16(sp)
    80003b48:	e426                	sd	s1,8(sp)
    80003b4a:	1000                	addi	s0,sp,32
    80003b4c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	e54080e7          	jalr	-428(ra) # 800039a2 <iunlock>
  iput(ip);
    80003b56:	8526                	mv	a0,s1
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	f42080e7          	jalr	-190(ra) # 80003a9a <iput>
}
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6105                	addi	sp,sp,32
    80003b68:	8082                	ret

0000000080003b6a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b6a:	1141                	addi	sp,sp,-16
    80003b6c:	e422                	sd	s0,8(sp)
    80003b6e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b70:	411c                	lw	a5,0(a0)
    80003b72:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b74:	415c                	lw	a5,4(a0)
    80003b76:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b78:	04451783          	lh	a5,68(a0)
    80003b7c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b80:	04a51783          	lh	a5,74(a0)
    80003b84:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b88:	04c56783          	lwu	a5,76(a0)
    80003b8c:	e99c                	sd	a5,16(a1)
}
    80003b8e:	6422                	ld	s0,8(sp)
    80003b90:	0141                	addi	sp,sp,16
    80003b92:	8082                	ret

0000000080003b94 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b94:	457c                	lw	a5,76(a0)
    80003b96:	0ed7e963          	bltu	a5,a3,80003c88 <readi+0xf4>
{
    80003b9a:	7159                	addi	sp,sp,-112
    80003b9c:	f486                	sd	ra,104(sp)
    80003b9e:	f0a2                	sd	s0,96(sp)
    80003ba0:	eca6                	sd	s1,88(sp)
    80003ba2:	e8ca                	sd	s2,80(sp)
    80003ba4:	e4ce                	sd	s3,72(sp)
    80003ba6:	e0d2                	sd	s4,64(sp)
    80003ba8:	fc56                	sd	s5,56(sp)
    80003baa:	f85a                	sd	s6,48(sp)
    80003bac:	f45e                	sd	s7,40(sp)
    80003bae:	f062                	sd	s8,32(sp)
    80003bb0:	ec66                	sd	s9,24(sp)
    80003bb2:	e86a                	sd	s10,16(sp)
    80003bb4:	e46e                	sd	s11,8(sp)
    80003bb6:	1880                	addi	s0,sp,112
    80003bb8:	8baa                	mv	s7,a0
    80003bba:	8c2e                	mv	s8,a1
    80003bbc:	8ab2                	mv	s5,a2
    80003bbe:	84b6                	mv	s1,a3
    80003bc0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc2:	9f35                	addw	a4,a4,a3
    return 0;
    80003bc4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bc6:	0ad76063          	bltu	a4,a3,80003c66 <readi+0xd2>
  if(off + n > ip->size)
    80003bca:	00e7f463          	bgeu	a5,a4,80003bd2 <readi+0x3e>
    n = ip->size - off;
    80003bce:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd2:	0a0b0963          	beqz	s6,80003c84 <readi+0xf0>
    80003bd6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bdc:	5cfd                	li	s9,-1
    80003bde:	a82d                	j	80003c18 <readi+0x84>
    80003be0:	020a1d93          	slli	s11,s4,0x20
    80003be4:	020ddd93          	srli	s11,s11,0x20
    80003be8:	05890613          	addi	a2,s2,88
    80003bec:	86ee                	mv	a3,s11
    80003bee:	963a                	add	a2,a2,a4
    80003bf0:	85d6                	mv	a1,s5
    80003bf2:	8562                	mv	a0,s8
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	816080e7          	jalr	-2026(ra) # 8000240a <either_copyout>
    80003bfc:	05950d63          	beq	a0,s9,80003c56 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c00:	854a                	mv	a0,s2
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	60c080e7          	jalr	1548(ra) # 8000320e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c0a:	013a09bb          	addw	s3,s4,s3
    80003c0e:	009a04bb          	addw	s1,s4,s1
    80003c12:	9aee                	add	s5,s5,s11
    80003c14:	0569f763          	bgeu	s3,s6,80003c62 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c18:	000ba903          	lw	s2,0(s7)
    80003c1c:	00a4d59b          	srliw	a1,s1,0xa
    80003c20:	855e                	mv	a0,s7
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	8b0080e7          	jalr	-1872(ra) # 800034d2 <bmap>
    80003c2a:	0005059b          	sext.w	a1,a0
    80003c2e:	854a                	mv	a0,s2
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	4ae080e7          	jalr	1198(ra) # 800030de <bread>
    80003c38:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3a:	3ff4f713          	andi	a4,s1,1023
    80003c3e:	40ed07bb          	subw	a5,s10,a4
    80003c42:	413b06bb          	subw	a3,s6,s3
    80003c46:	8a3e                	mv	s4,a5
    80003c48:	2781                	sext.w	a5,a5
    80003c4a:	0006861b          	sext.w	a2,a3
    80003c4e:	f8f679e3          	bgeu	a2,a5,80003be0 <readi+0x4c>
    80003c52:	8a36                	mv	s4,a3
    80003c54:	b771                	j	80003be0 <readi+0x4c>
      brelse(bp);
    80003c56:	854a                	mv	a0,s2
    80003c58:	fffff097          	auipc	ra,0xfffff
    80003c5c:	5b6080e7          	jalr	1462(ra) # 8000320e <brelse>
      tot = -1;
    80003c60:	59fd                	li	s3,-1
  }
  return tot;
    80003c62:	0009851b          	sext.w	a0,s3
}
    80003c66:	70a6                	ld	ra,104(sp)
    80003c68:	7406                	ld	s0,96(sp)
    80003c6a:	64e6                	ld	s1,88(sp)
    80003c6c:	6946                	ld	s2,80(sp)
    80003c6e:	69a6                	ld	s3,72(sp)
    80003c70:	6a06                	ld	s4,64(sp)
    80003c72:	7ae2                	ld	s5,56(sp)
    80003c74:	7b42                	ld	s6,48(sp)
    80003c76:	7ba2                	ld	s7,40(sp)
    80003c78:	7c02                	ld	s8,32(sp)
    80003c7a:	6ce2                	ld	s9,24(sp)
    80003c7c:	6d42                	ld	s10,16(sp)
    80003c7e:	6da2                	ld	s11,8(sp)
    80003c80:	6165                	addi	sp,sp,112
    80003c82:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c84:	89da                	mv	s3,s6
    80003c86:	bff1                	j	80003c62 <readi+0xce>
    return 0;
    80003c88:	4501                	li	a0,0
}
    80003c8a:	8082                	ret

0000000080003c8c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c8c:	457c                	lw	a5,76(a0)
    80003c8e:	10d7e863          	bltu	a5,a3,80003d9e <writei+0x112>
{
    80003c92:	7159                	addi	sp,sp,-112
    80003c94:	f486                	sd	ra,104(sp)
    80003c96:	f0a2                	sd	s0,96(sp)
    80003c98:	eca6                	sd	s1,88(sp)
    80003c9a:	e8ca                	sd	s2,80(sp)
    80003c9c:	e4ce                	sd	s3,72(sp)
    80003c9e:	e0d2                	sd	s4,64(sp)
    80003ca0:	fc56                	sd	s5,56(sp)
    80003ca2:	f85a                	sd	s6,48(sp)
    80003ca4:	f45e                	sd	s7,40(sp)
    80003ca6:	f062                	sd	s8,32(sp)
    80003ca8:	ec66                	sd	s9,24(sp)
    80003caa:	e86a                	sd	s10,16(sp)
    80003cac:	e46e                	sd	s11,8(sp)
    80003cae:	1880                	addi	s0,sp,112
    80003cb0:	8b2a                	mv	s6,a0
    80003cb2:	8c2e                	mv	s8,a1
    80003cb4:	8ab2                	mv	s5,a2
    80003cb6:	8936                	mv	s2,a3
    80003cb8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cba:	00e687bb          	addw	a5,a3,a4
    80003cbe:	0ed7e263          	bltu	a5,a3,80003da2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cc2:	00043737          	lui	a4,0x43
    80003cc6:	0ef76063          	bltu	a4,a5,80003da6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cca:	0c0b8863          	beqz	s7,80003d9a <writei+0x10e>
    80003cce:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cd4:	5cfd                	li	s9,-1
    80003cd6:	a091                	j	80003d1a <writei+0x8e>
    80003cd8:	02099d93          	slli	s11,s3,0x20
    80003cdc:	020ddd93          	srli	s11,s11,0x20
    80003ce0:	05848513          	addi	a0,s1,88
    80003ce4:	86ee                	mv	a3,s11
    80003ce6:	8656                	mv	a2,s5
    80003ce8:	85e2                	mv	a1,s8
    80003cea:	953a                	add	a0,a0,a4
    80003cec:	ffffe097          	auipc	ra,0xffffe
    80003cf0:	774080e7          	jalr	1908(ra) # 80002460 <either_copyin>
    80003cf4:	07950263          	beq	a0,s9,80003d58 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cf8:	8526                	mv	a0,s1
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	790080e7          	jalr	1936(ra) # 8000448a <log_write>
    brelse(bp);
    80003d02:	8526                	mv	a0,s1
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	50a080e7          	jalr	1290(ra) # 8000320e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0c:	01498a3b          	addw	s4,s3,s4
    80003d10:	0129893b          	addw	s2,s3,s2
    80003d14:	9aee                	add	s5,s5,s11
    80003d16:	057a7663          	bgeu	s4,s7,80003d62 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d1a:	000b2483          	lw	s1,0(s6)
    80003d1e:	00a9559b          	srliw	a1,s2,0xa
    80003d22:	855a                	mv	a0,s6
    80003d24:	fffff097          	auipc	ra,0xfffff
    80003d28:	7ae080e7          	jalr	1966(ra) # 800034d2 <bmap>
    80003d2c:	0005059b          	sext.w	a1,a0
    80003d30:	8526                	mv	a0,s1
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	3ac080e7          	jalr	940(ra) # 800030de <bread>
    80003d3a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3c:	3ff97713          	andi	a4,s2,1023
    80003d40:	40ed07bb          	subw	a5,s10,a4
    80003d44:	414b86bb          	subw	a3,s7,s4
    80003d48:	89be                	mv	s3,a5
    80003d4a:	2781                	sext.w	a5,a5
    80003d4c:	0006861b          	sext.w	a2,a3
    80003d50:	f8f674e3          	bgeu	a2,a5,80003cd8 <writei+0x4c>
    80003d54:	89b6                	mv	s3,a3
    80003d56:	b749                	j	80003cd8 <writei+0x4c>
      brelse(bp);
    80003d58:	8526                	mv	a0,s1
    80003d5a:	fffff097          	auipc	ra,0xfffff
    80003d5e:	4b4080e7          	jalr	1204(ra) # 8000320e <brelse>
  }

  if(off > ip->size)
    80003d62:	04cb2783          	lw	a5,76(s6)
    80003d66:	0127f463          	bgeu	a5,s2,80003d6e <writei+0xe2>
    ip->size = off;
    80003d6a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d6e:	855a                	mv	a0,s6
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	aa6080e7          	jalr	-1370(ra) # 80003816 <iupdate>

  return tot;
    80003d78:	000a051b          	sext.w	a0,s4
}
    80003d7c:	70a6                	ld	ra,104(sp)
    80003d7e:	7406                	ld	s0,96(sp)
    80003d80:	64e6                	ld	s1,88(sp)
    80003d82:	6946                	ld	s2,80(sp)
    80003d84:	69a6                	ld	s3,72(sp)
    80003d86:	6a06                	ld	s4,64(sp)
    80003d88:	7ae2                	ld	s5,56(sp)
    80003d8a:	7b42                	ld	s6,48(sp)
    80003d8c:	7ba2                	ld	s7,40(sp)
    80003d8e:	7c02                	ld	s8,32(sp)
    80003d90:	6ce2                	ld	s9,24(sp)
    80003d92:	6d42                	ld	s10,16(sp)
    80003d94:	6da2                	ld	s11,8(sp)
    80003d96:	6165                	addi	sp,sp,112
    80003d98:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d9a:	8a5e                	mv	s4,s7
    80003d9c:	bfc9                	j	80003d6e <writei+0xe2>
    return -1;
    80003d9e:	557d                	li	a0,-1
}
    80003da0:	8082                	ret
    return -1;
    80003da2:	557d                	li	a0,-1
    80003da4:	bfe1                	j	80003d7c <writei+0xf0>
    return -1;
    80003da6:	557d                	li	a0,-1
    80003da8:	bfd1                	j	80003d7c <writei+0xf0>

0000000080003daa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003daa:	1141                	addi	sp,sp,-16
    80003dac:	e406                	sd	ra,8(sp)
    80003dae:	e022                	sd	s0,0(sp)
    80003db0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db2:	4639                	li	a2,14
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	ffa080e7          	jalr	-6(ra) # 80000dae <strncmp>
}
    80003dbc:	60a2                	ld	ra,8(sp)
    80003dbe:	6402                	ld	s0,0(sp)
    80003dc0:	0141                	addi	sp,sp,16
    80003dc2:	8082                	ret

0000000080003dc4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc4:	7139                	addi	sp,sp,-64
    80003dc6:	fc06                	sd	ra,56(sp)
    80003dc8:	f822                	sd	s0,48(sp)
    80003dca:	f426                	sd	s1,40(sp)
    80003dcc:	f04a                	sd	s2,32(sp)
    80003dce:	ec4e                	sd	s3,24(sp)
    80003dd0:	e852                	sd	s4,16(sp)
    80003dd2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd4:	04451703          	lh	a4,68(a0)
    80003dd8:	4785                	li	a5,1
    80003dda:	00f71a63          	bne	a4,a5,80003dee <dirlookup+0x2a>
    80003dde:	892a                	mv	s2,a0
    80003de0:	89ae                	mv	s3,a1
    80003de2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de4:	457c                	lw	a5,76(a0)
    80003de6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003de8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dea:	e79d                	bnez	a5,80003e18 <dirlookup+0x54>
    80003dec:	a8a5                	j	80003e64 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dee:	00004517          	auipc	a0,0x4
    80003df2:	7f250513          	addi	a0,a0,2034 # 800085e0 <syscalls+0x1b0>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	73a080e7          	jalr	1850(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003dfe:	00004517          	auipc	a0,0x4
    80003e02:	7fa50513          	addi	a0,a0,2042 # 800085f8 <syscalls+0x1c8>
    80003e06:	ffffc097          	auipc	ra,0xffffc
    80003e0a:	72a080e7          	jalr	1834(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0e:	24c1                	addiw	s1,s1,16
    80003e10:	04c92783          	lw	a5,76(s2)
    80003e14:	04f4f763          	bgeu	s1,a5,80003e62 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e18:	4741                	li	a4,16
    80003e1a:	86a6                	mv	a3,s1
    80003e1c:	fc040613          	addi	a2,s0,-64
    80003e20:	4581                	li	a1,0
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	d70080e7          	jalr	-656(ra) # 80003b94 <readi>
    80003e2c:	47c1                	li	a5,16
    80003e2e:	fcf518e3          	bne	a0,a5,80003dfe <dirlookup+0x3a>
    if(de.inum == 0)
    80003e32:	fc045783          	lhu	a5,-64(s0)
    80003e36:	dfe1                	beqz	a5,80003e0e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e38:	fc240593          	addi	a1,s0,-62
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	f6c080e7          	jalr	-148(ra) # 80003daa <namecmp>
    80003e46:	f561                	bnez	a0,80003e0e <dirlookup+0x4a>
      if(poff)
    80003e48:	000a0463          	beqz	s4,80003e50 <dirlookup+0x8c>
        *poff = off;
    80003e4c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e50:	fc045583          	lhu	a1,-64(s0)
    80003e54:	00092503          	lw	a0,0(s2)
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	754080e7          	jalr	1876(ra) # 800035ac <iget>
    80003e60:	a011                	j	80003e64 <dirlookup+0xa0>
  return 0;
    80003e62:	4501                	li	a0,0
}
    80003e64:	70e2                	ld	ra,56(sp)
    80003e66:	7442                	ld	s0,48(sp)
    80003e68:	74a2                	ld	s1,40(sp)
    80003e6a:	7902                	ld	s2,32(sp)
    80003e6c:	69e2                	ld	s3,24(sp)
    80003e6e:	6a42                	ld	s4,16(sp)
    80003e70:	6121                	addi	sp,sp,64
    80003e72:	8082                	ret

0000000080003e74 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e74:	711d                	addi	sp,sp,-96
    80003e76:	ec86                	sd	ra,88(sp)
    80003e78:	e8a2                	sd	s0,80(sp)
    80003e7a:	e4a6                	sd	s1,72(sp)
    80003e7c:	e0ca                	sd	s2,64(sp)
    80003e7e:	fc4e                	sd	s3,56(sp)
    80003e80:	f852                	sd	s4,48(sp)
    80003e82:	f456                	sd	s5,40(sp)
    80003e84:	f05a                	sd	s6,32(sp)
    80003e86:	ec5e                	sd	s7,24(sp)
    80003e88:	e862                	sd	s8,16(sp)
    80003e8a:	e466                	sd	s9,8(sp)
    80003e8c:	1080                	addi	s0,sp,96
    80003e8e:	84aa                	mv	s1,a0
    80003e90:	8b2e                	mv	s6,a1
    80003e92:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e94:	00054703          	lbu	a4,0(a0)
    80003e98:	02f00793          	li	a5,47
    80003e9c:	02f70363          	beq	a4,a5,80003ec2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ea0:	ffffe097          	auipc	ra,0xffffe
    80003ea4:	af4080e7          	jalr	-1292(ra) # 80001994 <myproc>
    80003ea8:	15053503          	ld	a0,336(a0)
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	9f6080e7          	jalr	-1546(ra) # 800038a2 <idup>
    80003eb4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eb6:	02f00913          	li	s2,47
  len = path - s;
    80003eba:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ebc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ebe:	4c05                	li	s8,1
    80003ec0:	a865                	j	80003f78 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ec2:	4585                	li	a1,1
    80003ec4:	4505                	li	a0,1
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	6e6080e7          	jalr	1766(ra) # 800035ac <iget>
    80003ece:	89aa                	mv	s3,a0
    80003ed0:	b7dd                	j	80003eb6 <namex+0x42>
      iunlockput(ip);
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	c6e080e7          	jalr	-914(ra) # 80003b42 <iunlockput>
      return 0;
    80003edc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ede:	854e                	mv	a0,s3
    80003ee0:	60e6                	ld	ra,88(sp)
    80003ee2:	6446                	ld	s0,80(sp)
    80003ee4:	64a6                	ld	s1,72(sp)
    80003ee6:	6906                	ld	s2,64(sp)
    80003ee8:	79e2                	ld	s3,56(sp)
    80003eea:	7a42                	ld	s4,48(sp)
    80003eec:	7aa2                	ld	s5,40(sp)
    80003eee:	7b02                	ld	s6,32(sp)
    80003ef0:	6be2                	ld	s7,24(sp)
    80003ef2:	6c42                	ld	s8,16(sp)
    80003ef4:	6ca2                	ld	s9,8(sp)
    80003ef6:	6125                	addi	sp,sp,96
    80003ef8:	8082                	ret
      iunlock(ip);
    80003efa:	854e                	mv	a0,s3
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	aa6080e7          	jalr	-1370(ra) # 800039a2 <iunlock>
      return ip;
    80003f04:	bfe9                	j	80003ede <namex+0x6a>
      iunlockput(ip);
    80003f06:	854e                	mv	a0,s3
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	c3a080e7          	jalr	-966(ra) # 80003b42 <iunlockput>
      return 0;
    80003f10:	89d2                	mv	s3,s4
    80003f12:	b7f1                	j	80003ede <namex+0x6a>
  len = path - s;
    80003f14:	40b48633          	sub	a2,s1,a1
    80003f18:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f1c:	094cd463          	bge	s9,s4,80003fa4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f20:	4639                	li	a2,14
    80003f22:	8556                	mv	a0,s5
    80003f24:	ffffd097          	auipc	ra,0xffffd
    80003f28:	e0e080e7          	jalr	-498(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	01279763          	bne	a5,s2,80003f3e <namex+0xca>
    path++;
    80003f34:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	ff278de3          	beq	a5,s2,80003f34 <namex+0xc0>
    ilock(ip);
    80003f3e:	854e                	mv	a0,s3
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	9a0080e7          	jalr	-1632(ra) # 800038e0 <ilock>
    if(ip->type != T_DIR){
    80003f48:	04499783          	lh	a5,68(s3)
    80003f4c:	f98793e3          	bne	a5,s8,80003ed2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f50:	000b0563          	beqz	s6,80003f5a <namex+0xe6>
    80003f54:	0004c783          	lbu	a5,0(s1)
    80003f58:	d3cd                	beqz	a5,80003efa <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f5a:	865e                	mv	a2,s7
    80003f5c:	85d6                	mv	a1,s5
    80003f5e:	854e                	mv	a0,s3
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	e64080e7          	jalr	-412(ra) # 80003dc4 <dirlookup>
    80003f68:	8a2a                	mv	s4,a0
    80003f6a:	dd51                	beqz	a0,80003f06 <namex+0x92>
    iunlockput(ip);
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	bd4080e7          	jalr	-1068(ra) # 80003b42 <iunlockput>
    ip = next;
    80003f76:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f78:	0004c783          	lbu	a5,0(s1)
    80003f7c:	05279763          	bne	a5,s2,80003fca <namex+0x156>
    path++;
    80003f80:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f82:	0004c783          	lbu	a5,0(s1)
    80003f86:	ff278de3          	beq	a5,s2,80003f80 <namex+0x10c>
  if(*path == 0)
    80003f8a:	c79d                	beqz	a5,80003fb8 <namex+0x144>
    path++;
    80003f8c:	85a6                	mv	a1,s1
  len = path - s;
    80003f8e:	8a5e                	mv	s4,s7
    80003f90:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f92:	01278963          	beq	a5,s2,80003fa4 <namex+0x130>
    80003f96:	dfbd                	beqz	a5,80003f14 <namex+0xa0>
    path++;
    80003f98:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f9a:	0004c783          	lbu	a5,0(s1)
    80003f9e:	ff279ce3          	bne	a5,s2,80003f96 <namex+0x122>
    80003fa2:	bf8d                	j	80003f14 <namex+0xa0>
    memmove(name, s, len);
    80003fa4:	2601                	sext.w	a2,a2
    80003fa6:	8556                	mv	a0,s5
    80003fa8:	ffffd097          	auipc	ra,0xffffd
    80003fac:	d8a080e7          	jalr	-630(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003fb0:	9a56                	add	s4,s4,s5
    80003fb2:	000a0023          	sb	zero,0(s4)
    80003fb6:	bf9d                	j	80003f2c <namex+0xb8>
  if(nameiparent){
    80003fb8:	f20b03e3          	beqz	s6,80003ede <namex+0x6a>
    iput(ip);
    80003fbc:	854e                	mv	a0,s3
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	adc080e7          	jalr	-1316(ra) # 80003a9a <iput>
    return 0;
    80003fc6:	4981                	li	s3,0
    80003fc8:	bf19                	j	80003ede <namex+0x6a>
  if(*path == 0)
    80003fca:	d7fd                	beqz	a5,80003fb8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fcc:	0004c783          	lbu	a5,0(s1)
    80003fd0:	85a6                	mv	a1,s1
    80003fd2:	b7d1                	j	80003f96 <namex+0x122>

0000000080003fd4 <dirlink>:
{
    80003fd4:	7139                	addi	sp,sp,-64
    80003fd6:	fc06                	sd	ra,56(sp)
    80003fd8:	f822                	sd	s0,48(sp)
    80003fda:	f426                	sd	s1,40(sp)
    80003fdc:	f04a                	sd	s2,32(sp)
    80003fde:	ec4e                	sd	s3,24(sp)
    80003fe0:	e852                	sd	s4,16(sp)
    80003fe2:	0080                	addi	s0,sp,64
    80003fe4:	892a                	mv	s2,a0
    80003fe6:	8a2e                	mv	s4,a1
    80003fe8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fea:	4601                	li	a2,0
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	dd8080e7          	jalr	-552(ra) # 80003dc4 <dirlookup>
    80003ff4:	e93d                	bnez	a0,8000406a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff6:	04c92483          	lw	s1,76(s2)
    80003ffa:	c49d                	beqz	s1,80004028 <dirlink+0x54>
    80003ffc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffe:	4741                	li	a4,16
    80004000:	86a6                	mv	a3,s1
    80004002:	fc040613          	addi	a2,s0,-64
    80004006:	4581                	li	a1,0
    80004008:	854a                	mv	a0,s2
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	b8a080e7          	jalr	-1142(ra) # 80003b94 <readi>
    80004012:	47c1                	li	a5,16
    80004014:	06f51163          	bne	a0,a5,80004076 <dirlink+0xa2>
    if(de.inum == 0)
    80004018:	fc045783          	lhu	a5,-64(s0)
    8000401c:	c791                	beqz	a5,80004028 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401e:	24c1                	addiw	s1,s1,16
    80004020:	04c92783          	lw	a5,76(s2)
    80004024:	fcf4ede3          	bltu	s1,a5,80003ffe <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004028:	4639                	li	a2,14
    8000402a:	85d2                	mv	a1,s4
    8000402c:	fc240513          	addi	a0,s0,-62
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	dba080e7          	jalr	-582(ra) # 80000dea <strncpy>
  de.inum = inum;
    80004038:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403c:	4741                	li	a4,16
    8000403e:	86a6                	mv	a3,s1
    80004040:	fc040613          	addi	a2,s0,-64
    80004044:	4581                	li	a1,0
    80004046:	854a                	mv	a0,s2
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	c44080e7          	jalr	-956(ra) # 80003c8c <writei>
    80004050:	872a                	mv	a4,a0
    80004052:	47c1                	li	a5,16
  return 0;
    80004054:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004056:	02f71863          	bne	a4,a5,80004086 <dirlink+0xb2>
}
    8000405a:	70e2                	ld	ra,56(sp)
    8000405c:	7442                	ld	s0,48(sp)
    8000405e:	74a2                	ld	s1,40(sp)
    80004060:	7902                	ld	s2,32(sp)
    80004062:	69e2                	ld	s3,24(sp)
    80004064:	6a42                	ld	s4,16(sp)
    80004066:	6121                	addi	sp,sp,64
    80004068:	8082                	ret
    iput(ip);
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	a30080e7          	jalr	-1488(ra) # 80003a9a <iput>
    return -1;
    80004072:	557d                	li	a0,-1
    80004074:	b7dd                	j	8000405a <dirlink+0x86>
      panic("dirlink read");
    80004076:	00004517          	auipc	a0,0x4
    8000407a:	59250513          	addi	a0,a0,1426 # 80008608 <syscalls+0x1d8>
    8000407e:	ffffc097          	auipc	ra,0xffffc
    80004082:	4b2080e7          	jalr	1202(ra) # 80000530 <panic>
    panic("dirlink");
    80004086:	00004517          	auipc	a0,0x4
    8000408a:	69250513          	addi	a0,a0,1682 # 80008718 <syscalls+0x2e8>
    8000408e:	ffffc097          	auipc	ra,0xffffc
    80004092:	4a2080e7          	jalr	1186(ra) # 80000530 <panic>

0000000080004096 <namei>:

struct inode*
namei(char *path)
{
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000409e:	fe040613          	addi	a2,s0,-32
    800040a2:	4581                	li	a1,0
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	dd0080e7          	jalr	-560(ra) # 80003e74 <namex>
}
    800040ac:	60e2                	ld	ra,24(sp)
    800040ae:	6442                	ld	s0,16(sp)
    800040b0:	6105                	addi	sp,sp,32
    800040b2:	8082                	ret

00000000800040b4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040b4:	1141                	addi	sp,sp,-16
    800040b6:	e406                	sd	ra,8(sp)
    800040b8:	e022                	sd	s0,0(sp)
    800040ba:	0800                	addi	s0,sp,16
    800040bc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040be:	4585                	li	a1,1
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	db4080e7          	jalr	-588(ra) # 80003e74 <namex>
}
    800040c8:	60a2                	ld	ra,8(sp)
    800040ca:	6402                	ld	s0,0(sp)
    800040cc:	0141                	addi	sp,sp,16
    800040ce:	8082                	ret

00000000800040d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040d0:	1101                	addi	sp,sp,-32
    800040d2:	ec06                	sd	ra,24(sp)
    800040d4:	e822                	sd	s0,16(sp)
    800040d6:	e426                	sd	s1,8(sp)
    800040d8:	e04a                	sd	s2,0(sp)
    800040da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040dc:	0001d917          	auipc	s2,0x1d
    800040e0:	39490913          	addi	s2,s2,916 # 80021470 <log>
    800040e4:	01892583          	lw	a1,24(s2)
    800040e8:	02892503          	lw	a0,40(s2)
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	ff2080e7          	jalr	-14(ra) # 800030de <bread>
    800040f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040f6:	02c92683          	lw	a3,44(s2)
    800040fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040fc:	02d05763          	blez	a3,8000412a <write_head+0x5a>
    80004100:	0001d797          	auipc	a5,0x1d
    80004104:	3a078793          	addi	a5,a5,928 # 800214a0 <log+0x30>
    80004108:	05c50713          	addi	a4,a0,92
    8000410c:	36fd                	addiw	a3,a3,-1
    8000410e:	1682                	slli	a3,a3,0x20
    80004110:	9281                	srli	a3,a3,0x20
    80004112:	068a                	slli	a3,a3,0x2
    80004114:	0001d617          	auipc	a2,0x1d
    80004118:	39060613          	addi	a2,a2,912 # 800214a4 <log+0x34>
    8000411c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000411e:	4390                	lw	a2,0(a5)
    80004120:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004122:	0791                	addi	a5,a5,4
    80004124:	0711                	addi	a4,a4,4
    80004126:	fed79ce3          	bne	a5,a3,8000411e <write_head+0x4e>
  }
  bwrite(buf);
    8000412a:	8526                	mv	a0,s1
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	0a4080e7          	jalr	164(ra) # 800031d0 <bwrite>
  brelse(buf);
    80004134:	8526                	mv	a0,s1
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	0d8080e7          	jalr	216(ra) # 8000320e <brelse>
}
    8000413e:	60e2                	ld	ra,24(sp)
    80004140:	6442                	ld	s0,16(sp)
    80004142:	64a2                	ld	s1,8(sp)
    80004144:	6902                	ld	s2,0(sp)
    80004146:	6105                	addi	sp,sp,32
    80004148:	8082                	ret

000000008000414a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000414a:	0001d797          	auipc	a5,0x1d
    8000414e:	3527a783          	lw	a5,850(a5) # 8002149c <log+0x2c>
    80004152:	0af05d63          	blez	a5,8000420c <install_trans+0xc2>
{
    80004156:	7139                	addi	sp,sp,-64
    80004158:	fc06                	sd	ra,56(sp)
    8000415a:	f822                	sd	s0,48(sp)
    8000415c:	f426                	sd	s1,40(sp)
    8000415e:	f04a                	sd	s2,32(sp)
    80004160:	ec4e                	sd	s3,24(sp)
    80004162:	e852                	sd	s4,16(sp)
    80004164:	e456                	sd	s5,8(sp)
    80004166:	e05a                	sd	s6,0(sp)
    80004168:	0080                	addi	s0,sp,64
    8000416a:	8b2a                	mv	s6,a0
    8000416c:	0001da97          	auipc	s5,0x1d
    80004170:	334a8a93          	addi	s5,s5,820 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004174:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004176:	0001d997          	auipc	s3,0x1d
    8000417a:	2fa98993          	addi	s3,s3,762 # 80021470 <log>
    8000417e:	a035                	j	800041aa <install_trans+0x60>
      bunpin(dbuf);
    80004180:	8526                	mv	a0,s1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	166080e7          	jalr	358(ra) # 800032e8 <bunpin>
    brelse(lbuf);
    8000418a:	854a                	mv	a0,s2
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	082080e7          	jalr	130(ra) # 8000320e <brelse>
    brelse(dbuf);
    80004194:	8526                	mv	a0,s1
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	078080e7          	jalr	120(ra) # 8000320e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000419e:	2a05                	addiw	s4,s4,1
    800041a0:	0a91                	addi	s5,s5,4
    800041a2:	02c9a783          	lw	a5,44(s3)
    800041a6:	04fa5963          	bge	s4,a5,800041f8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041aa:	0189a583          	lw	a1,24(s3)
    800041ae:	014585bb          	addw	a1,a1,s4
    800041b2:	2585                	addiw	a1,a1,1
    800041b4:	0289a503          	lw	a0,40(s3)
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	f26080e7          	jalr	-218(ra) # 800030de <bread>
    800041c0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041c2:	000aa583          	lw	a1,0(s5)
    800041c6:	0289a503          	lw	a0,40(s3)
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	f14080e7          	jalr	-236(ra) # 800030de <bread>
    800041d2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041d4:	40000613          	li	a2,1024
    800041d8:	05890593          	addi	a1,s2,88
    800041dc:	05850513          	addi	a0,a0,88
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	b52080e7          	jalr	-1198(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041e8:	8526                	mv	a0,s1
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	fe6080e7          	jalr	-26(ra) # 800031d0 <bwrite>
    if(recovering == 0)
    800041f2:	f80b1ce3          	bnez	s6,8000418a <install_trans+0x40>
    800041f6:	b769                	j	80004180 <install_trans+0x36>
}
    800041f8:	70e2                	ld	ra,56(sp)
    800041fa:	7442                	ld	s0,48(sp)
    800041fc:	74a2                	ld	s1,40(sp)
    800041fe:	7902                	ld	s2,32(sp)
    80004200:	69e2                	ld	s3,24(sp)
    80004202:	6a42                	ld	s4,16(sp)
    80004204:	6aa2                	ld	s5,8(sp)
    80004206:	6b02                	ld	s6,0(sp)
    80004208:	6121                	addi	sp,sp,64
    8000420a:	8082                	ret
    8000420c:	8082                	ret

000000008000420e <initlog>:
{
    8000420e:	7179                	addi	sp,sp,-48
    80004210:	f406                	sd	ra,40(sp)
    80004212:	f022                	sd	s0,32(sp)
    80004214:	ec26                	sd	s1,24(sp)
    80004216:	e84a                	sd	s2,16(sp)
    80004218:	e44e                	sd	s3,8(sp)
    8000421a:	1800                	addi	s0,sp,48
    8000421c:	892a                	mv	s2,a0
    8000421e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004220:	0001d497          	auipc	s1,0x1d
    80004224:	25048493          	addi	s1,s1,592 # 80021470 <log>
    80004228:	00004597          	auipc	a1,0x4
    8000422c:	3f058593          	addi	a1,a1,1008 # 80008618 <syscalls+0x1e8>
    80004230:	8526                	mv	a0,s1
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	914080e7          	jalr	-1772(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000423a:	0149a583          	lw	a1,20(s3)
    8000423e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004240:	0109a783          	lw	a5,16(s3)
    80004244:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004246:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000424a:	854a                	mv	a0,s2
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	e92080e7          	jalr	-366(ra) # 800030de <bread>
  log.lh.n = lh->n;
    80004254:	4d3c                	lw	a5,88(a0)
    80004256:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004258:	02f05563          	blez	a5,80004282 <initlog+0x74>
    8000425c:	05c50713          	addi	a4,a0,92
    80004260:	0001d697          	auipc	a3,0x1d
    80004264:	24068693          	addi	a3,a3,576 # 800214a0 <log+0x30>
    80004268:	37fd                	addiw	a5,a5,-1
    8000426a:	1782                	slli	a5,a5,0x20
    8000426c:	9381                	srli	a5,a5,0x20
    8000426e:	078a                	slli	a5,a5,0x2
    80004270:	06050613          	addi	a2,a0,96
    80004274:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004276:	4310                	lw	a2,0(a4)
    80004278:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000427a:	0711                	addi	a4,a4,4
    8000427c:	0691                	addi	a3,a3,4
    8000427e:	fef71ce3          	bne	a4,a5,80004276 <initlog+0x68>
  brelse(buf);
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	f8c080e7          	jalr	-116(ra) # 8000320e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000428a:	4505                	li	a0,1
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	ebe080e7          	jalr	-322(ra) # 8000414a <install_trans>
  log.lh.n = 0;
    80004294:	0001d797          	auipc	a5,0x1d
    80004298:	2007a423          	sw	zero,520(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	e34080e7          	jalr	-460(ra) # 800040d0 <write_head>
}
    800042a4:	70a2                	ld	ra,40(sp)
    800042a6:	7402                	ld	s0,32(sp)
    800042a8:	64e2                	ld	s1,24(sp)
    800042aa:	6942                	ld	s2,16(sp)
    800042ac:	69a2                	ld	s3,8(sp)
    800042ae:	6145                	addi	sp,sp,48
    800042b0:	8082                	ret

00000000800042b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042b2:	1101                	addi	sp,sp,-32
    800042b4:	ec06                	sd	ra,24(sp)
    800042b6:	e822                	sd	s0,16(sp)
    800042b8:	e426                	sd	s1,8(sp)
    800042ba:	e04a                	sd	s2,0(sp)
    800042bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042be:	0001d517          	auipc	a0,0x1d
    800042c2:	1b250513          	addi	a0,a0,434 # 80021470 <log>
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800042ce:	0001d497          	auipc	s1,0x1d
    800042d2:	1a248493          	addi	s1,s1,418 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d6:	4979                	li	s2,30
    800042d8:	a039                	j	800042e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042da:	85a6                	mv	a1,s1
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffe097          	auipc	ra,0xffffe
    800042e2:	d88080e7          	jalr	-632(ra) # 80002066 <sleep>
    if(log.committing){
    800042e6:	50dc                	lw	a5,36(s1)
    800042e8:	fbed                	bnez	a5,800042da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ea:	509c                	lw	a5,32(s1)
    800042ec:	0017871b          	addiw	a4,a5,1
    800042f0:	0007069b          	sext.w	a3,a4
    800042f4:	0027179b          	slliw	a5,a4,0x2
    800042f8:	9fb9                	addw	a5,a5,a4
    800042fa:	0017979b          	slliw	a5,a5,0x1
    800042fe:	54d8                	lw	a4,44(s1)
    80004300:	9fb9                	addw	a5,a5,a4
    80004302:	00f95963          	bge	s2,a5,80004314 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004306:	85a6                	mv	a1,s1
    80004308:	8526                	mv	a0,s1
    8000430a:	ffffe097          	auipc	ra,0xffffe
    8000430e:	d5c080e7          	jalr	-676(ra) # 80002066 <sleep>
    80004312:	bfd1                	j	800042e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004314:	0001d517          	auipc	a0,0x1d
    80004318:	15c50513          	addi	a0,a0,348 # 80021470 <log>
    8000431c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	96c080e7          	jalr	-1684(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004326:	60e2                	ld	ra,24(sp)
    80004328:	6442                	ld	s0,16(sp)
    8000432a:	64a2                	ld	s1,8(sp)
    8000432c:	6902                	ld	s2,0(sp)
    8000432e:	6105                	addi	sp,sp,32
    80004330:	8082                	ret

0000000080004332 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004332:	7139                	addi	sp,sp,-64
    80004334:	fc06                	sd	ra,56(sp)
    80004336:	f822                	sd	s0,48(sp)
    80004338:	f426                	sd	s1,40(sp)
    8000433a:	f04a                	sd	s2,32(sp)
    8000433c:	ec4e                	sd	s3,24(sp)
    8000433e:	e852                	sd	s4,16(sp)
    80004340:	e456                	sd	s5,8(sp)
    80004342:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004344:	0001d497          	auipc	s1,0x1d
    80004348:	12c48493          	addi	s1,s1,300 # 80021470 <log>
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	888080e7          	jalr	-1912(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004356:	509c                	lw	a5,32(s1)
    80004358:	37fd                	addiw	a5,a5,-1
    8000435a:	0007891b          	sext.w	s2,a5
    8000435e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004360:	50dc                	lw	a5,36(s1)
    80004362:	efb9                	bnez	a5,800043c0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004364:	06091663          	bnez	s2,800043d0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004368:	0001d497          	auipc	s1,0x1d
    8000436c:	10848493          	addi	s1,s1,264 # 80021470 <log>
    80004370:	4785                	li	a5,1
    80004372:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004374:	8526                	mv	a0,s1
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	914080e7          	jalr	-1772(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000437e:	54dc                	lw	a5,44(s1)
    80004380:	06f04763          	bgtz	a5,800043ee <end_op+0xbc>
    acquire(&log.lock);
    80004384:	0001d497          	auipc	s1,0x1d
    80004388:	0ec48493          	addi	s1,s1,236 # 80021470 <log>
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	848080e7          	jalr	-1976(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004396:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffe097          	auipc	ra,0xffffe
    800043a0:	e56080e7          	jalr	-426(ra) # 800021f2 <wakeup>
    release(&log.lock);
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	8e4080e7          	jalr	-1820(ra) # 80000c8a <release>
}
    800043ae:	70e2                	ld	ra,56(sp)
    800043b0:	7442                	ld	s0,48(sp)
    800043b2:	74a2                	ld	s1,40(sp)
    800043b4:	7902                	ld	s2,32(sp)
    800043b6:	69e2                	ld	s3,24(sp)
    800043b8:	6a42                	ld	s4,16(sp)
    800043ba:	6aa2                	ld	s5,8(sp)
    800043bc:	6121                	addi	sp,sp,64
    800043be:	8082                	ret
    panic("log.committing");
    800043c0:	00004517          	auipc	a0,0x4
    800043c4:	26050513          	addi	a0,a0,608 # 80008620 <syscalls+0x1f0>
    800043c8:	ffffc097          	auipc	ra,0xffffc
    800043cc:	168080e7          	jalr	360(ra) # 80000530 <panic>
    wakeup(&log);
    800043d0:	0001d497          	auipc	s1,0x1d
    800043d4:	0a048493          	addi	s1,s1,160 # 80021470 <log>
    800043d8:	8526                	mv	a0,s1
    800043da:	ffffe097          	auipc	ra,0xffffe
    800043de:	e18080e7          	jalr	-488(ra) # 800021f2 <wakeup>
  release(&log.lock);
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
  if(do_commit){
    800043ec:	b7c9                	j	800043ae <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ee:	0001da97          	auipc	s5,0x1d
    800043f2:	0b2a8a93          	addi	s5,s5,178 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043f6:	0001da17          	auipc	s4,0x1d
    800043fa:	07aa0a13          	addi	s4,s4,122 # 80021470 <log>
    800043fe:	018a2583          	lw	a1,24(s4)
    80004402:	012585bb          	addw	a1,a1,s2
    80004406:	2585                	addiw	a1,a1,1
    80004408:	028a2503          	lw	a0,40(s4)
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	cd2080e7          	jalr	-814(ra) # 800030de <bread>
    80004414:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004416:	000aa583          	lw	a1,0(s5)
    8000441a:	028a2503          	lw	a0,40(s4)
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	cc0080e7          	jalr	-832(ra) # 800030de <bread>
    80004426:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004428:	40000613          	li	a2,1024
    8000442c:	05850593          	addi	a1,a0,88
    80004430:	05848513          	addi	a0,s1,88
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	8fe080e7          	jalr	-1794(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    8000443c:	8526                	mv	a0,s1
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	d92080e7          	jalr	-622(ra) # 800031d0 <bwrite>
    brelse(from);
    80004446:	854e                	mv	a0,s3
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	dc6080e7          	jalr	-570(ra) # 8000320e <brelse>
    brelse(to);
    80004450:	8526                	mv	a0,s1
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	dbc080e7          	jalr	-580(ra) # 8000320e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000445a:	2905                	addiw	s2,s2,1
    8000445c:	0a91                	addi	s5,s5,4
    8000445e:	02ca2783          	lw	a5,44(s4)
    80004462:	f8f94ee3          	blt	s2,a5,800043fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	c6a080e7          	jalr	-918(ra) # 800040d0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000446e:	4501                	li	a0,0
    80004470:	00000097          	auipc	ra,0x0
    80004474:	cda080e7          	jalr	-806(ra) # 8000414a <install_trans>
    log.lh.n = 0;
    80004478:	0001d797          	auipc	a5,0x1d
    8000447c:	0207a223          	sw	zero,36(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004480:	00000097          	auipc	ra,0x0
    80004484:	c50080e7          	jalr	-944(ra) # 800040d0 <write_head>
    80004488:	bdf5                	j	80004384 <end_op+0x52>

000000008000448a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	e04a                	sd	s2,0(sp)
    80004494:	1000                	addi	s0,sp,32
    80004496:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004498:	0001d917          	auipc	s2,0x1d
    8000449c:	fd890913          	addi	s2,s2,-40 # 80021470 <log>
    800044a0:	854a                	mv	a0,s2
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	734080e7          	jalr	1844(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044aa:	02c92603          	lw	a2,44(s2)
    800044ae:	47f5                	li	a5,29
    800044b0:	06c7c563          	blt	a5,a2,8000451a <log_write+0x90>
    800044b4:	0001d797          	auipc	a5,0x1d
    800044b8:	fd87a783          	lw	a5,-40(a5) # 8002148c <log+0x1c>
    800044bc:	37fd                	addiw	a5,a5,-1
    800044be:	04f65e63          	bge	a2,a5,8000451a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044c2:	0001d797          	auipc	a5,0x1d
    800044c6:	fce7a783          	lw	a5,-50(a5) # 80021490 <log+0x20>
    800044ca:	06f05063          	blez	a5,8000452a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044ce:	4781                	li	a5,0
    800044d0:	06c05563          	blez	a2,8000453a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044d4:	44cc                	lw	a1,12(s1)
    800044d6:	0001d717          	auipc	a4,0x1d
    800044da:	fca70713          	addi	a4,a4,-54 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044e0:	4314                	lw	a3,0(a4)
    800044e2:	04b68c63          	beq	a3,a1,8000453a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044e6:	2785                	addiw	a5,a5,1
    800044e8:	0711                	addi	a4,a4,4
    800044ea:	fef61be3          	bne	a2,a5,800044e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044ee:	0621                	addi	a2,a2,8
    800044f0:	060a                	slli	a2,a2,0x2
    800044f2:	0001d797          	auipc	a5,0x1d
    800044f6:	f7e78793          	addi	a5,a5,-130 # 80021470 <log>
    800044fa:	963e                	add	a2,a2,a5
    800044fc:	44dc                	lw	a5,12(s1)
    800044fe:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004500:	8526                	mv	a0,s1
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	daa080e7          	jalr	-598(ra) # 800032ac <bpin>
    log.lh.n++;
    8000450a:	0001d717          	auipc	a4,0x1d
    8000450e:	f6670713          	addi	a4,a4,-154 # 80021470 <log>
    80004512:	575c                	lw	a5,44(a4)
    80004514:	2785                	addiw	a5,a5,1
    80004516:	d75c                	sw	a5,44(a4)
    80004518:	a835                	j	80004554 <log_write+0xca>
    panic("too big a transaction");
    8000451a:	00004517          	auipc	a0,0x4
    8000451e:	11650513          	addi	a0,a0,278 # 80008630 <syscalls+0x200>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	00e080e7          	jalr	14(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    8000452a:	00004517          	auipc	a0,0x4
    8000452e:	11e50513          	addi	a0,a0,286 # 80008648 <syscalls+0x218>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	ffe080e7          	jalr	-2(ra) # 80000530 <panic>
  log.lh.block[i] = b->blockno;
    8000453a:	00878713          	addi	a4,a5,8
    8000453e:	00271693          	slli	a3,a4,0x2
    80004542:	0001d717          	auipc	a4,0x1d
    80004546:	f2e70713          	addi	a4,a4,-210 # 80021470 <log>
    8000454a:	9736                	add	a4,a4,a3
    8000454c:	44d4                	lw	a3,12(s1)
    8000454e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004550:	faf608e3          	beq	a2,a5,80004500 <log_write+0x76>
  }
  release(&log.lock);
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	f1c50513          	addi	a0,a0,-228 # 80021470 <log>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	72e080e7          	jalr	1838(ra) # 80000c8a <release>
}
    80004564:	60e2                	ld	ra,24(sp)
    80004566:	6442                	ld	s0,16(sp)
    80004568:	64a2                	ld	s1,8(sp)
    8000456a:	6902                	ld	s2,0(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret

0000000080004570 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004570:	1101                	addi	sp,sp,-32
    80004572:	ec06                	sd	ra,24(sp)
    80004574:	e822                	sd	s0,16(sp)
    80004576:	e426                	sd	s1,8(sp)
    80004578:	e04a                	sd	s2,0(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
    8000457e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004580:	00004597          	auipc	a1,0x4
    80004584:	0e858593          	addi	a1,a1,232 # 80008668 <syscalls+0x238>
    80004588:	0521                	addi	a0,a0,8
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	5bc080e7          	jalr	1468(ra) # 80000b46 <initlock>
  lk->name = name;
    80004592:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004596:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000459a:	0204a423          	sw	zero,40(s1)
}
    8000459e:	60e2                	ld	ra,24(sp)
    800045a0:	6442                	ld	s0,16(sp)
    800045a2:	64a2                	ld	s1,8(sp)
    800045a4:	6902                	ld	s2,0(sp)
    800045a6:	6105                	addi	sp,sp,32
    800045a8:	8082                	ret

00000000800045aa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045aa:	1101                	addi	sp,sp,-32
    800045ac:	ec06                	sd	ra,24(sp)
    800045ae:	e822                	sd	s0,16(sp)
    800045b0:	e426                	sd	s1,8(sp)
    800045b2:	e04a                	sd	s2,0(sp)
    800045b4:	1000                	addi	s0,sp,32
    800045b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b8:	00850913          	addi	s2,a0,8
    800045bc:	854a                	mv	a0,s2
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	618080e7          	jalr	1560(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800045c6:	409c                	lw	a5,0(s1)
    800045c8:	cb89                	beqz	a5,800045da <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ca:	85ca                	mv	a1,s2
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffe097          	auipc	ra,0xffffe
    800045d2:	a98080e7          	jalr	-1384(ra) # 80002066 <sleep>
  while (lk->locked) {
    800045d6:	409c                	lw	a5,0(s1)
    800045d8:	fbed                	bnez	a5,800045ca <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045da:	4785                	li	a5,1
    800045dc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045de:	ffffd097          	auipc	ra,0xffffd
    800045e2:	3b6080e7          	jalr	950(ra) # 80001994 <myproc>
    800045e6:	591c                	lw	a5,48(a0)
    800045e8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045ea:	854a                	mv	a0,s2
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	69e080e7          	jalr	1694(ra) # 80000c8a <release>
}
    800045f4:	60e2                	ld	ra,24(sp)
    800045f6:	6442                	ld	s0,16(sp)
    800045f8:	64a2                	ld	s1,8(sp)
    800045fa:	6902                	ld	s2,0(sp)
    800045fc:	6105                	addi	sp,sp,32
    800045fe:	8082                	ret

0000000080004600 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004600:	1101                	addi	sp,sp,-32
    80004602:	ec06                	sd	ra,24(sp)
    80004604:	e822                	sd	s0,16(sp)
    80004606:	e426                	sd	s1,8(sp)
    80004608:	e04a                	sd	s2,0(sp)
    8000460a:	1000                	addi	s0,sp,32
    8000460c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460e:	00850913          	addi	s2,a0,8
    80004612:	854a                	mv	a0,s2
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	5c2080e7          	jalr	1474(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000461c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004620:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004624:	8526                	mv	a0,s1
    80004626:	ffffe097          	auipc	ra,0xffffe
    8000462a:	bcc080e7          	jalr	-1076(ra) # 800021f2 <wakeup>
  release(&lk->lk);
    8000462e:	854a                	mv	a0,s2
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	65a080e7          	jalr	1626(ra) # 80000c8a <release>
}
    80004638:	60e2                	ld	ra,24(sp)
    8000463a:	6442                	ld	s0,16(sp)
    8000463c:	64a2                	ld	s1,8(sp)
    8000463e:	6902                	ld	s2,0(sp)
    80004640:	6105                	addi	sp,sp,32
    80004642:	8082                	ret

0000000080004644 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004644:	7179                	addi	sp,sp,-48
    80004646:	f406                	sd	ra,40(sp)
    80004648:	f022                	sd	s0,32(sp)
    8000464a:	ec26                	sd	s1,24(sp)
    8000464c:	e84a                	sd	s2,16(sp)
    8000464e:	e44e                	sd	s3,8(sp)
    80004650:	1800                	addi	s0,sp,48
    80004652:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004654:	00850913          	addi	s2,a0,8
    80004658:	854a                	mv	a0,s2
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	57c080e7          	jalr	1404(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004662:	409c                	lw	a5,0(s1)
    80004664:	ef99                	bnez	a5,80004682 <holdingsleep+0x3e>
    80004666:	4481                	li	s1,0
  release(&lk->lk);
    80004668:	854a                	mv	a0,s2
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	620080e7          	jalr	1568(ra) # 80000c8a <release>
  return r;
}
    80004672:	8526                	mv	a0,s1
    80004674:	70a2                	ld	ra,40(sp)
    80004676:	7402                	ld	s0,32(sp)
    80004678:	64e2                	ld	s1,24(sp)
    8000467a:	6942                	ld	s2,16(sp)
    8000467c:	69a2                	ld	s3,8(sp)
    8000467e:	6145                	addi	sp,sp,48
    80004680:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004682:	0284a983          	lw	s3,40(s1)
    80004686:	ffffd097          	auipc	ra,0xffffd
    8000468a:	30e080e7          	jalr	782(ra) # 80001994 <myproc>
    8000468e:	5904                	lw	s1,48(a0)
    80004690:	413484b3          	sub	s1,s1,s3
    80004694:	0014b493          	seqz	s1,s1
    80004698:	bfc1                	j	80004668 <holdingsleep+0x24>

000000008000469a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000469a:	1141                	addi	sp,sp,-16
    8000469c:	e406                	sd	ra,8(sp)
    8000469e:	e022                	sd	s0,0(sp)
    800046a0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046a2:	00004597          	auipc	a1,0x4
    800046a6:	fd658593          	addi	a1,a1,-42 # 80008678 <syscalls+0x248>
    800046aa:	0001d517          	auipc	a0,0x1d
    800046ae:	f0e50513          	addi	a0,a0,-242 # 800215b8 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	494080e7          	jalr	1172(ra) # 80000b46 <initlock>
}
    800046ba:	60a2                	ld	ra,8(sp)
    800046bc:	6402                	ld	s0,0(sp)
    800046be:	0141                	addi	sp,sp,16
    800046c0:	8082                	ret

00000000800046c2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046c2:	1101                	addi	sp,sp,-32
    800046c4:	ec06                	sd	ra,24(sp)
    800046c6:	e822                	sd	s0,16(sp)
    800046c8:	e426                	sd	s1,8(sp)
    800046ca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046cc:	0001d517          	auipc	a0,0x1d
    800046d0:	eec50513          	addi	a0,a0,-276 # 800215b8 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	502080e7          	jalr	1282(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046dc:	0001d497          	auipc	s1,0x1d
    800046e0:	ef448493          	addi	s1,s1,-268 # 800215d0 <ftable+0x18>
    800046e4:	0001e717          	auipc	a4,0x1e
    800046e8:	e8c70713          	addi	a4,a4,-372 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800046ec:	40dc                	lw	a5,4(s1)
    800046ee:	cf99                	beqz	a5,8000470c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046f0:	02848493          	addi	s1,s1,40
    800046f4:	fee49ce3          	bne	s1,a4,800046ec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046f8:	0001d517          	auipc	a0,0x1d
    800046fc:	ec050513          	addi	a0,a0,-320 # 800215b8 <ftable>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	58a080e7          	jalr	1418(ra) # 80000c8a <release>
  return 0;
    80004708:	4481                	li	s1,0
    8000470a:	a819                	j	80004720 <filealloc+0x5e>
      f->ref = 1;
    8000470c:	4785                	li	a5,1
    8000470e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004710:	0001d517          	auipc	a0,0x1d
    80004714:	ea850513          	addi	a0,a0,-344 # 800215b8 <ftable>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	572080e7          	jalr	1394(ra) # 80000c8a <release>
}
    80004720:	8526                	mv	a0,s1
    80004722:	60e2                	ld	ra,24(sp)
    80004724:	6442                	ld	s0,16(sp)
    80004726:	64a2                	ld	s1,8(sp)
    80004728:	6105                	addi	sp,sp,32
    8000472a:	8082                	ret

000000008000472c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000472c:	1101                	addi	sp,sp,-32
    8000472e:	ec06                	sd	ra,24(sp)
    80004730:	e822                	sd	s0,16(sp)
    80004732:	e426                	sd	s1,8(sp)
    80004734:	1000                	addi	s0,sp,32
    80004736:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004738:	0001d517          	auipc	a0,0x1d
    8000473c:	e8050513          	addi	a0,a0,-384 # 800215b8 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	496080e7          	jalr	1174(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004748:	40dc                	lw	a5,4(s1)
    8000474a:	02f05263          	blez	a5,8000476e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000474e:	2785                	addiw	a5,a5,1
    80004750:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004752:	0001d517          	auipc	a0,0x1d
    80004756:	e6650513          	addi	a0,a0,-410 # 800215b8 <ftable>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	530080e7          	jalr	1328(ra) # 80000c8a <release>
  return f;
}
    80004762:	8526                	mv	a0,s1
    80004764:	60e2                	ld	ra,24(sp)
    80004766:	6442                	ld	s0,16(sp)
    80004768:	64a2                	ld	s1,8(sp)
    8000476a:	6105                	addi	sp,sp,32
    8000476c:	8082                	ret
    panic("filedup");
    8000476e:	00004517          	auipc	a0,0x4
    80004772:	f1250513          	addi	a0,a0,-238 # 80008680 <syscalls+0x250>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	dba080e7          	jalr	-582(ra) # 80000530 <panic>

000000008000477e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000477e:	7139                	addi	sp,sp,-64
    80004780:	fc06                	sd	ra,56(sp)
    80004782:	f822                	sd	s0,48(sp)
    80004784:	f426                	sd	s1,40(sp)
    80004786:	f04a                	sd	s2,32(sp)
    80004788:	ec4e                	sd	s3,24(sp)
    8000478a:	e852                	sd	s4,16(sp)
    8000478c:	e456                	sd	s5,8(sp)
    8000478e:	0080                	addi	s0,sp,64
    80004790:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004792:	0001d517          	auipc	a0,0x1d
    80004796:	e2650513          	addi	a0,a0,-474 # 800215b8 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	43c080e7          	jalr	1084(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047a2:	40dc                	lw	a5,4(s1)
    800047a4:	06f05163          	blez	a5,80004806 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047a8:	37fd                	addiw	a5,a5,-1
    800047aa:	0007871b          	sext.w	a4,a5
    800047ae:	c0dc                	sw	a5,4(s1)
    800047b0:	06e04363          	bgtz	a4,80004816 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047b4:	0004a903          	lw	s2,0(s1)
    800047b8:	0094ca83          	lbu	s5,9(s1)
    800047bc:	0104ba03          	ld	s4,16(s1)
    800047c0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047c4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047c8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047cc:	0001d517          	auipc	a0,0x1d
    800047d0:	dec50513          	addi	a0,a0,-532 # 800215b8 <ftable>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	4b6080e7          	jalr	1206(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800047dc:	4785                	li	a5,1
    800047de:	04f90d63          	beq	s2,a5,80004838 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047e2:	3979                	addiw	s2,s2,-2
    800047e4:	4785                	li	a5,1
    800047e6:	0527e063          	bltu	a5,s2,80004826 <fileclose+0xa8>
    begin_op();
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	ac8080e7          	jalr	-1336(ra) # 800042b2 <begin_op>
    iput(ff.ip);
    800047f2:	854e                	mv	a0,s3
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	2a6080e7          	jalr	678(ra) # 80003a9a <iput>
    end_op();
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	b36080e7          	jalr	-1226(ra) # 80004332 <end_op>
    80004804:	a00d                	j	80004826 <fileclose+0xa8>
    panic("fileclose");
    80004806:	00004517          	auipc	a0,0x4
    8000480a:	e8250513          	addi	a0,a0,-382 # 80008688 <syscalls+0x258>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	d22080e7          	jalr	-734(ra) # 80000530 <panic>
    release(&ftable.lock);
    80004816:	0001d517          	auipc	a0,0x1d
    8000481a:	da250513          	addi	a0,a0,-606 # 800215b8 <ftable>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	46c080e7          	jalr	1132(ra) # 80000c8a <release>
  }
}
    80004826:	70e2                	ld	ra,56(sp)
    80004828:	7442                	ld	s0,48(sp)
    8000482a:	74a2                	ld	s1,40(sp)
    8000482c:	7902                	ld	s2,32(sp)
    8000482e:	69e2                	ld	s3,24(sp)
    80004830:	6a42                	ld	s4,16(sp)
    80004832:	6aa2                	ld	s5,8(sp)
    80004834:	6121                	addi	sp,sp,64
    80004836:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004838:	85d6                	mv	a1,s5
    8000483a:	8552                	mv	a0,s4
    8000483c:	00000097          	auipc	ra,0x0
    80004840:	34c080e7          	jalr	844(ra) # 80004b88 <pipeclose>
    80004844:	b7cd                	j	80004826 <fileclose+0xa8>

0000000080004846 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004846:	715d                	addi	sp,sp,-80
    80004848:	e486                	sd	ra,72(sp)
    8000484a:	e0a2                	sd	s0,64(sp)
    8000484c:	fc26                	sd	s1,56(sp)
    8000484e:	f84a                	sd	s2,48(sp)
    80004850:	f44e                	sd	s3,40(sp)
    80004852:	0880                	addi	s0,sp,80
    80004854:	84aa                	mv	s1,a0
    80004856:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004858:	ffffd097          	auipc	ra,0xffffd
    8000485c:	13c080e7          	jalr	316(ra) # 80001994 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004860:	409c                	lw	a5,0(s1)
    80004862:	37f9                	addiw	a5,a5,-2
    80004864:	4705                	li	a4,1
    80004866:	04f76763          	bltu	a4,a5,800048b4 <filestat+0x6e>
    8000486a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000486c:	6c88                	ld	a0,24(s1)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	072080e7          	jalr	114(ra) # 800038e0 <ilock>
    stati(f->ip, &st);
    80004876:	fb840593          	addi	a1,s0,-72
    8000487a:	6c88                	ld	a0,24(s1)
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	2ee080e7          	jalr	750(ra) # 80003b6a <stati>
    iunlock(f->ip);
    80004884:	6c88                	ld	a0,24(s1)
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	11c080e7          	jalr	284(ra) # 800039a2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000488e:	46e1                	li	a3,24
    80004890:	fb840613          	addi	a2,s0,-72
    80004894:	85ce                	mv	a1,s3
    80004896:	05093503          	ld	a0,80(s2)
    8000489a:	ffffd097          	auipc	ra,0xffffd
    8000489e:	dbc080e7          	jalr	-580(ra) # 80001656 <copyout>
    800048a2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048a6:	60a6                	ld	ra,72(sp)
    800048a8:	6406                	ld	s0,64(sp)
    800048aa:	74e2                	ld	s1,56(sp)
    800048ac:	7942                	ld	s2,48(sp)
    800048ae:	79a2                	ld	s3,40(sp)
    800048b0:	6161                	addi	sp,sp,80
    800048b2:	8082                	ret
  return -1;
    800048b4:	557d                	li	a0,-1
    800048b6:	bfc5                	j	800048a6 <filestat+0x60>

00000000800048b8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048b8:	7179                	addi	sp,sp,-48
    800048ba:	f406                	sd	ra,40(sp)
    800048bc:	f022                	sd	s0,32(sp)
    800048be:	ec26                	sd	s1,24(sp)
    800048c0:	e84a                	sd	s2,16(sp)
    800048c2:	e44e                	sd	s3,8(sp)
    800048c4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048c6:	00854783          	lbu	a5,8(a0)
    800048ca:	c3d5                	beqz	a5,8000496e <fileread+0xb6>
    800048cc:	84aa                	mv	s1,a0
    800048ce:	89ae                	mv	s3,a1
    800048d0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d2:	411c                	lw	a5,0(a0)
    800048d4:	4705                	li	a4,1
    800048d6:	04e78963          	beq	a5,a4,80004928 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048da:	470d                	li	a4,3
    800048dc:	04e78d63          	beq	a5,a4,80004936 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048e0:	4709                	li	a4,2
    800048e2:	06e79e63          	bne	a5,a4,8000495e <fileread+0xa6>
    ilock(f->ip);
    800048e6:	6d08                	ld	a0,24(a0)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	ff8080e7          	jalr	-8(ra) # 800038e0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048f0:	874a                	mv	a4,s2
    800048f2:	5094                	lw	a3,32(s1)
    800048f4:	864e                	mv	a2,s3
    800048f6:	4585                	li	a1,1
    800048f8:	6c88                	ld	a0,24(s1)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	29a080e7          	jalr	666(ra) # 80003b94 <readi>
    80004902:	892a                	mv	s2,a0
    80004904:	00a05563          	blez	a0,8000490e <fileread+0x56>
      f->off += r;
    80004908:	509c                	lw	a5,32(s1)
    8000490a:	9fa9                	addw	a5,a5,a0
    8000490c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	092080e7          	jalr	146(ra) # 800039a2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004918:	854a                	mv	a0,s2
    8000491a:	70a2                	ld	ra,40(sp)
    8000491c:	7402                	ld	s0,32(sp)
    8000491e:	64e2                	ld	s1,24(sp)
    80004920:	6942                	ld	s2,16(sp)
    80004922:	69a2                	ld	s3,8(sp)
    80004924:	6145                	addi	sp,sp,48
    80004926:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004928:	6908                	ld	a0,16(a0)
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	3c8080e7          	jalr	968(ra) # 80004cf2 <piperead>
    80004932:	892a                	mv	s2,a0
    80004934:	b7d5                	j	80004918 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004936:	02451783          	lh	a5,36(a0)
    8000493a:	03079693          	slli	a3,a5,0x30
    8000493e:	92c1                	srli	a3,a3,0x30
    80004940:	4725                	li	a4,9
    80004942:	02d76863          	bltu	a4,a3,80004972 <fileread+0xba>
    80004946:	0792                	slli	a5,a5,0x4
    80004948:	0001d717          	auipc	a4,0x1d
    8000494c:	bd070713          	addi	a4,a4,-1072 # 80021518 <devsw>
    80004950:	97ba                	add	a5,a5,a4
    80004952:	639c                	ld	a5,0(a5)
    80004954:	c38d                	beqz	a5,80004976 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004956:	4505                	li	a0,1
    80004958:	9782                	jalr	a5
    8000495a:	892a                	mv	s2,a0
    8000495c:	bf75                	j	80004918 <fileread+0x60>
    panic("fileread");
    8000495e:	00004517          	auipc	a0,0x4
    80004962:	d3a50513          	addi	a0,a0,-710 # 80008698 <syscalls+0x268>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	bca080e7          	jalr	-1078(ra) # 80000530 <panic>
    return -1;
    8000496e:	597d                	li	s2,-1
    80004970:	b765                	j	80004918 <fileread+0x60>
      return -1;
    80004972:	597d                	li	s2,-1
    80004974:	b755                	j	80004918 <fileread+0x60>
    80004976:	597d                	li	s2,-1
    80004978:	b745                	j	80004918 <fileread+0x60>

000000008000497a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000497a:	715d                	addi	sp,sp,-80
    8000497c:	e486                	sd	ra,72(sp)
    8000497e:	e0a2                	sd	s0,64(sp)
    80004980:	fc26                	sd	s1,56(sp)
    80004982:	f84a                	sd	s2,48(sp)
    80004984:	f44e                	sd	s3,40(sp)
    80004986:	f052                	sd	s4,32(sp)
    80004988:	ec56                	sd	s5,24(sp)
    8000498a:	e85a                	sd	s6,16(sp)
    8000498c:	e45e                	sd	s7,8(sp)
    8000498e:	e062                	sd	s8,0(sp)
    80004990:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004992:	00954783          	lbu	a5,9(a0)
    80004996:	10078663          	beqz	a5,80004aa2 <filewrite+0x128>
    8000499a:	892a                	mv	s2,a0
    8000499c:	8aae                	mv	s5,a1
    8000499e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049a0:	411c                	lw	a5,0(a0)
    800049a2:	4705                	li	a4,1
    800049a4:	02e78263          	beq	a5,a4,800049c8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a8:	470d                	li	a4,3
    800049aa:	02e78663          	beq	a5,a4,800049d6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ae:	4709                	li	a4,2
    800049b0:	0ee79163          	bne	a5,a4,80004a92 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049b4:	0ac05d63          	blez	a2,80004a6e <filewrite+0xf4>
    int i = 0;
    800049b8:	4981                	li	s3,0
    800049ba:	6b05                	lui	s6,0x1
    800049bc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049c0:	6b85                	lui	s7,0x1
    800049c2:	c00b8b9b          	addiw	s7,s7,-1024
    800049c6:	a861                	j	80004a5e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049c8:	6908                	ld	a0,16(a0)
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	22e080e7          	jalr	558(ra) # 80004bf8 <pipewrite>
    800049d2:	8a2a                	mv	s4,a0
    800049d4:	a045                	j	80004a74 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049d6:	02451783          	lh	a5,36(a0)
    800049da:	03079693          	slli	a3,a5,0x30
    800049de:	92c1                	srli	a3,a3,0x30
    800049e0:	4725                	li	a4,9
    800049e2:	0cd76263          	bltu	a4,a3,80004aa6 <filewrite+0x12c>
    800049e6:	0792                	slli	a5,a5,0x4
    800049e8:	0001d717          	auipc	a4,0x1d
    800049ec:	b3070713          	addi	a4,a4,-1232 # 80021518 <devsw>
    800049f0:	97ba                	add	a5,a5,a4
    800049f2:	679c                	ld	a5,8(a5)
    800049f4:	cbdd                	beqz	a5,80004aaa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049f6:	4505                	li	a0,1
    800049f8:	9782                	jalr	a5
    800049fa:	8a2a                	mv	s4,a0
    800049fc:	a8a5                	j	80004a74 <filewrite+0xfa>
    800049fe:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a02:	00000097          	auipc	ra,0x0
    80004a06:	8b0080e7          	jalr	-1872(ra) # 800042b2 <begin_op>
      ilock(f->ip);
    80004a0a:	01893503          	ld	a0,24(s2)
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	ed2080e7          	jalr	-302(ra) # 800038e0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a16:	8762                	mv	a4,s8
    80004a18:	02092683          	lw	a3,32(s2)
    80004a1c:	01598633          	add	a2,s3,s5
    80004a20:	4585                	li	a1,1
    80004a22:	01893503          	ld	a0,24(s2)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	266080e7          	jalr	614(ra) # 80003c8c <writei>
    80004a2e:	84aa                	mv	s1,a0
    80004a30:	00a05763          	blez	a0,80004a3e <filewrite+0xc4>
        f->off += r;
    80004a34:	02092783          	lw	a5,32(s2)
    80004a38:	9fa9                	addw	a5,a5,a0
    80004a3a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a3e:	01893503          	ld	a0,24(s2)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	f60080e7          	jalr	-160(ra) # 800039a2 <iunlock>
      end_op();
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	8e8080e7          	jalr	-1816(ra) # 80004332 <end_op>

      if(r != n1){
    80004a52:	009c1f63          	bne	s8,s1,80004a70 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a56:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a5a:	0149db63          	bge	s3,s4,80004a70 <filewrite+0xf6>
      int n1 = n - i;
    80004a5e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a62:	84be                	mv	s1,a5
    80004a64:	2781                	sext.w	a5,a5
    80004a66:	f8fb5ce3          	bge	s6,a5,800049fe <filewrite+0x84>
    80004a6a:	84de                	mv	s1,s7
    80004a6c:	bf49                	j	800049fe <filewrite+0x84>
    int i = 0;
    80004a6e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a70:	013a1f63          	bne	s4,s3,80004a8e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a74:	8552                	mv	a0,s4
    80004a76:	60a6                	ld	ra,72(sp)
    80004a78:	6406                	ld	s0,64(sp)
    80004a7a:	74e2                	ld	s1,56(sp)
    80004a7c:	7942                	ld	s2,48(sp)
    80004a7e:	79a2                	ld	s3,40(sp)
    80004a80:	7a02                	ld	s4,32(sp)
    80004a82:	6ae2                	ld	s5,24(sp)
    80004a84:	6b42                	ld	s6,16(sp)
    80004a86:	6ba2                	ld	s7,8(sp)
    80004a88:	6c02                	ld	s8,0(sp)
    80004a8a:	6161                	addi	sp,sp,80
    80004a8c:	8082                	ret
    ret = (i == n ? n : -1);
    80004a8e:	5a7d                	li	s4,-1
    80004a90:	b7d5                	j	80004a74 <filewrite+0xfa>
    panic("filewrite");
    80004a92:	00004517          	auipc	a0,0x4
    80004a96:	c1650513          	addi	a0,a0,-1002 # 800086a8 <syscalls+0x278>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	a96080e7          	jalr	-1386(ra) # 80000530 <panic>
    return -1;
    80004aa2:	5a7d                	li	s4,-1
    80004aa4:	bfc1                	j	80004a74 <filewrite+0xfa>
      return -1;
    80004aa6:	5a7d                	li	s4,-1
    80004aa8:	b7f1                	j	80004a74 <filewrite+0xfa>
    80004aaa:	5a7d                	li	s4,-1
    80004aac:	b7e1                	j	80004a74 <filewrite+0xfa>

0000000080004aae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aae:	7179                	addi	sp,sp,-48
    80004ab0:	f406                	sd	ra,40(sp)
    80004ab2:	f022                	sd	s0,32(sp)
    80004ab4:	ec26                	sd	s1,24(sp)
    80004ab6:	e84a                	sd	s2,16(sp)
    80004ab8:	e44e                	sd	s3,8(sp)
    80004aba:	e052                	sd	s4,0(sp)
    80004abc:	1800                	addi	s0,sp,48
    80004abe:	84aa                	mv	s1,a0
    80004ac0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ac2:	0005b023          	sd	zero,0(a1)
    80004ac6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	bf8080e7          	jalr	-1032(ra) # 800046c2 <filealloc>
    80004ad2:	e088                	sd	a0,0(s1)
    80004ad4:	c551                	beqz	a0,80004b60 <pipealloc+0xb2>
    80004ad6:	00000097          	auipc	ra,0x0
    80004ada:	bec080e7          	jalr	-1044(ra) # 800046c2 <filealloc>
    80004ade:	00aa3023          	sd	a0,0(s4)
    80004ae2:	c92d                	beqz	a0,80004b54 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	002080e7          	jalr	2(ra) # 80000ae6 <kalloc>
    80004aec:	892a                	mv	s2,a0
    80004aee:	c125                	beqz	a0,80004b4e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004af0:	4985                	li	s3,1
    80004af2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004af6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004afa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004afe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b02:	00004597          	auipc	a1,0x4
    80004b06:	bb658593          	addi	a1,a1,-1098 # 800086b8 <syscalls+0x288>
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	03c080e7          	jalr	60(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004b12:	609c                	ld	a5,0(s1)
    80004b14:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b18:	609c                	ld	a5,0(s1)
    80004b1a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b1e:	609c                	ld	a5,0(s1)
    80004b20:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b24:	609c                	ld	a5,0(s1)
    80004b26:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b2a:	000a3783          	ld	a5,0(s4)
    80004b2e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b32:	000a3783          	ld	a5,0(s4)
    80004b36:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b3a:	000a3783          	ld	a5,0(s4)
    80004b3e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b42:	000a3783          	ld	a5,0(s4)
    80004b46:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b4a:	4501                	li	a0,0
    80004b4c:	a025                	j	80004b74 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b4e:	6088                	ld	a0,0(s1)
    80004b50:	e501                	bnez	a0,80004b58 <pipealloc+0xaa>
    80004b52:	a039                	j	80004b60 <pipealloc+0xb2>
    80004b54:	6088                	ld	a0,0(s1)
    80004b56:	c51d                	beqz	a0,80004b84 <pipealloc+0xd6>
    fileclose(*f0);
    80004b58:	00000097          	auipc	ra,0x0
    80004b5c:	c26080e7          	jalr	-986(ra) # 8000477e <fileclose>
  if(*f1)
    80004b60:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b64:	557d                	li	a0,-1
  if(*f1)
    80004b66:	c799                	beqz	a5,80004b74 <pipealloc+0xc6>
    fileclose(*f1);
    80004b68:	853e                	mv	a0,a5
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	c14080e7          	jalr	-1004(ra) # 8000477e <fileclose>
  return -1;
    80004b72:	557d                	li	a0,-1
}
    80004b74:	70a2                	ld	ra,40(sp)
    80004b76:	7402                	ld	s0,32(sp)
    80004b78:	64e2                	ld	s1,24(sp)
    80004b7a:	6942                	ld	s2,16(sp)
    80004b7c:	69a2                	ld	s3,8(sp)
    80004b7e:	6a02                	ld	s4,0(sp)
    80004b80:	6145                	addi	sp,sp,48
    80004b82:	8082                	ret
  return -1;
    80004b84:	557d                	li	a0,-1
    80004b86:	b7fd                	j	80004b74 <pipealloc+0xc6>

0000000080004b88 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b88:	1101                	addi	sp,sp,-32
    80004b8a:	ec06                	sd	ra,24(sp)
    80004b8c:	e822                	sd	s0,16(sp)
    80004b8e:	e426                	sd	s1,8(sp)
    80004b90:	e04a                	sd	s2,0(sp)
    80004b92:	1000                	addi	s0,sp,32
    80004b94:	84aa                	mv	s1,a0
    80004b96:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	03e080e7          	jalr	62(ra) # 80000bd6 <acquire>
  if(writable){
    80004ba0:	02090d63          	beqz	s2,80004bda <pipeclose+0x52>
    pi->writeopen = 0;
    80004ba4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ba8:	21848513          	addi	a0,s1,536
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	646080e7          	jalr	1606(ra) # 800021f2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bb4:	2204b783          	ld	a5,544(s1)
    80004bb8:	eb95                	bnez	a5,80004bec <pipeclose+0x64>
    release(&pi->lock);
    80004bba:	8526                	mv	a0,s1
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	0ce080e7          	jalr	206(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	e24080e7          	jalr	-476(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004bce:	60e2                	ld	ra,24(sp)
    80004bd0:	6442                	ld	s0,16(sp)
    80004bd2:	64a2                	ld	s1,8(sp)
    80004bd4:	6902                	ld	s2,0(sp)
    80004bd6:	6105                	addi	sp,sp,32
    80004bd8:	8082                	ret
    pi->readopen = 0;
    80004bda:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bde:	21c48513          	addi	a0,s1,540
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	610080e7          	jalr	1552(ra) # 800021f2 <wakeup>
    80004bea:	b7e9                	j	80004bb4 <pipeclose+0x2c>
    release(&pi->lock);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
}
    80004bf6:	bfe1                	j	80004bce <pipeclose+0x46>

0000000080004bf8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bf8:	7159                	addi	sp,sp,-112
    80004bfa:	f486                	sd	ra,104(sp)
    80004bfc:	f0a2                	sd	s0,96(sp)
    80004bfe:	eca6                	sd	s1,88(sp)
    80004c00:	e8ca                	sd	s2,80(sp)
    80004c02:	e4ce                	sd	s3,72(sp)
    80004c04:	e0d2                	sd	s4,64(sp)
    80004c06:	fc56                	sd	s5,56(sp)
    80004c08:	f85a                	sd	s6,48(sp)
    80004c0a:	f45e                	sd	s7,40(sp)
    80004c0c:	f062                	sd	s8,32(sp)
    80004c0e:	ec66                	sd	s9,24(sp)
    80004c10:	1880                	addi	s0,sp,112
    80004c12:	84aa                	mv	s1,a0
    80004c14:	8aae                	mv	s5,a1
    80004c16:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	d7c080e7          	jalr	-644(ra) # 80001994 <myproc>
    80004c20:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	fb2080e7          	jalr	-78(ra) # 80000bd6 <acquire>
  while(i < n){
    80004c2c:	0d405163          	blez	s4,80004cee <pipewrite+0xf6>
    80004c30:	8ba6                	mv	s7,s1
  int i = 0;
    80004c32:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c34:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c36:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c3a:	21c48c13          	addi	s8,s1,540
    80004c3e:	a08d                	j	80004ca0 <pipewrite+0xa8>
      release(&pi->lock);
    80004c40:	8526                	mv	a0,s1
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	048080e7          	jalr	72(ra) # 80000c8a <release>
      return -1;
    80004c4a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c4c:	854a                	mv	a0,s2
    80004c4e:	70a6                	ld	ra,104(sp)
    80004c50:	7406                	ld	s0,96(sp)
    80004c52:	64e6                	ld	s1,88(sp)
    80004c54:	6946                	ld	s2,80(sp)
    80004c56:	69a6                	ld	s3,72(sp)
    80004c58:	6a06                	ld	s4,64(sp)
    80004c5a:	7ae2                	ld	s5,56(sp)
    80004c5c:	7b42                	ld	s6,48(sp)
    80004c5e:	7ba2                	ld	s7,40(sp)
    80004c60:	7c02                	ld	s8,32(sp)
    80004c62:	6ce2                	ld	s9,24(sp)
    80004c64:	6165                	addi	sp,sp,112
    80004c66:	8082                	ret
      wakeup(&pi->nread);
    80004c68:	8566                	mv	a0,s9
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	588080e7          	jalr	1416(ra) # 800021f2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c72:	85de                	mv	a1,s7
    80004c74:	8562                	mv	a0,s8
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	3f0080e7          	jalr	1008(ra) # 80002066 <sleep>
    80004c7e:	a839                	j	80004c9c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c80:	21c4a783          	lw	a5,540(s1)
    80004c84:	0017871b          	addiw	a4,a5,1
    80004c88:	20e4ae23          	sw	a4,540(s1)
    80004c8c:	1ff7f793          	andi	a5,a5,511
    80004c90:	97a6                	add	a5,a5,s1
    80004c92:	f9f44703          	lbu	a4,-97(s0)
    80004c96:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c9a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c9c:	03495d63          	bge	s2,s4,80004cd6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ca0:	2204a783          	lw	a5,544(s1)
    80004ca4:	dfd1                	beqz	a5,80004c40 <pipewrite+0x48>
    80004ca6:	0289a783          	lw	a5,40(s3)
    80004caa:	fbd9                	bnez	a5,80004c40 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cac:	2184a783          	lw	a5,536(s1)
    80004cb0:	21c4a703          	lw	a4,540(s1)
    80004cb4:	2007879b          	addiw	a5,a5,512
    80004cb8:	faf708e3          	beq	a4,a5,80004c68 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cbc:	4685                	li	a3,1
    80004cbe:	01590633          	add	a2,s2,s5
    80004cc2:	f9f40593          	addi	a1,s0,-97
    80004cc6:	0509b503          	ld	a0,80(s3)
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	a18080e7          	jalr	-1512(ra) # 800016e2 <copyin>
    80004cd2:	fb6517e3          	bne	a0,s6,80004c80 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cd6:	21848513          	addi	a0,s1,536
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	518080e7          	jalr	1304(ra) # 800021f2 <wakeup>
  release(&pi->lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	fa6080e7          	jalr	-90(ra) # 80000c8a <release>
  return i;
    80004cec:	b785                	j	80004c4c <pipewrite+0x54>
  int i = 0;
    80004cee:	4901                	li	s2,0
    80004cf0:	b7dd                	j	80004cd6 <pipewrite+0xde>

0000000080004cf2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cf2:	715d                	addi	sp,sp,-80
    80004cf4:	e486                	sd	ra,72(sp)
    80004cf6:	e0a2                	sd	s0,64(sp)
    80004cf8:	fc26                	sd	s1,56(sp)
    80004cfa:	f84a                	sd	s2,48(sp)
    80004cfc:	f44e                	sd	s3,40(sp)
    80004cfe:	f052                	sd	s4,32(sp)
    80004d00:	ec56                	sd	s5,24(sp)
    80004d02:	e85a                	sd	s6,16(sp)
    80004d04:	0880                	addi	s0,sp,80
    80004d06:	84aa                	mv	s1,a0
    80004d08:	892e                	mv	s2,a1
    80004d0a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	c88080e7          	jalr	-888(ra) # 80001994 <myproc>
    80004d14:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d16:	8b26                	mv	s6,s1
    80004d18:	8526                	mv	a0,s1
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	ebc080e7          	jalr	-324(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d22:	2184a703          	lw	a4,536(s1)
    80004d26:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d2a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2e:	02f71463          	bne	a4,a5,80004d56 <piperead+0x64>
    80004d32:	2244a783          	lw	a5,548(s1)
    80004d36:	c385                	beqz	a5,80004d56 <piperead+0x64>
    if(pr->killed){
    80004d38:	028a2783          	lw	a5,40(s4)
    80004d3c:	ebc1                	bnez	a5,80004dcc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3e:	85da                	mv	a1,s6
    80004d40:	854e                	mv	a0,s3
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	324080e7          	jalr	804(ra) # 80002066 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4a:	2184a703          	lw	a4,536(s1)
    80004d4e:	21c4a783          	lw	a5,540(s1)
    80004d52:	fef700e3          	beq	a4,a5,80004d32 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d56:	09505263          	blez	s5,80004dda <piperead+0xe8>
    80004d5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d5e:	2184a783          	lw	a5,536(s1)
    80004d62:	21c4a703          	lw	a4,540(s1)
    80004d66:	02f70d63          	beq	a4,a5,80004da0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d6a:	0017871b          	addiw	a4,a5,1
    80004d6e:	20e4ac23          	sw	a4,536(s1)
    80004d72:	1ff7f793          	andi	a5,a5,511
    80004d76:	97a6                	add	a5,a5,s1
    80004d78:	0187c783          	lbu	a5,24(a5)
    80004d7c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d80:	4685                	li	a3,1
    80004d82:	fbf40613          	addi	a2,s0,-65
    80004d86:	85ca                	mv	a1,s2
    80004d88:	050a3503          	ld	a0,80(s4)
    80004d8c:	ffffd097          	auipc	ra,0xffffd
    80004d90:	8ca080e7          	jalr	-1846(ra) # 80001656 <copyout>
    80004d94:	01650663          	beq	a0,s6,80004da0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d98:	2985                	addiw	s3,s3,1
    80004d9a:	0905                	addi	s2,s2,1
    80004d9c:	fd3a91e3          	bne	s5,s3,80004d5e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004da0:	21c48513          	addi	a0,s1,540
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	44e080e7          	jalr	1102(ra) # 800021f2 <wakeup>
  release(&pi->lock);
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	edc080e7          	jalr	-292(ra) # 80000c8a <release>
  return i;
}
    80004db6:	854e                	mv	a0,s3
    80004db8:	60a6                	ld	ra,72(sp)
    80004dba:	6406                	ld	s0,64(sp)
    80004dbc:	74e2                	ld	s1,56(sp)
    80004dbe:	7942                	ld	s2,48(sp)
    80004dc0:	79a2                	ld	s3,40(sp)
    80004dc2:	7a02                	ld	s4,32(sp)
    80004dc4:	6ae2                	ld	s5,24(sp)
    80004dc6:	6b42                	ld	s6,16(sp)
    80004dc8:	6161                	addi	sp,sp,80
    80004dca:	8082                	ret
      release(&pi->lock);
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	ebc080e7          	jalr	-324(ra) # 80000c8a <release>
      return -1;
    80004dd6:	59fd                	li	s3,-1
    80004dd8:	bff9                	j	80004db6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dda:	4981                	li	s3,0
    80004ddc:	b7d1                	j	80004da0 <piperead+0xae>

0000000080004dde <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dde:	df010113          	addi	sp,sp,-528
    80004de2:	20113423          	sd	ra,520(sp)
    80004de6:	20813023          	sd	s0,512(sp)
    80004dea:	ffa6                	sd	s1,504(sp)
    80004dec:	fbca                	sd	s2,496(sp)
    80004dee:	f7ce                	sd	s3,488(sp)
    80004df0:	f3d2                	sd	s4,480(sp)
    80004df2:	efd6                	sd	s5,472(sp)
    80004df4:	ebda                	sd	s6,464(sp)
    80004df6:	e7de                	sd	s7,456(sp)
    80004df8:	e3e2                	sd	s8,448(sp)
    80004dfa:	ff66                	sd	s9,440(sp)
    80004dfc:	fb6a                	sd	s10,432(sp)
    80004dfe:	f76e                	sd	s11,424(sp)
    80004e00:	0c00                	addi	s0,sp,528
    80004e02:	84aa                	mv	s1,a0
    80004e04:	dea43c23          	sd	a0,-520(s0)
    80004e08:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	b88080e7          	jalr	-1144(ra) # 80001994 <myproc>
    80004e14:	892a                	mv	s2,a0

  begin_op();
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	49c080e7          	jalr	1180(ra) # 800042b2 <begin_op>

  if((ip = namei(path)) == 0){
    80004e1e:	8526                	mv	a0,s1
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	276080e7          	jalr	630(ra) # 80004096 <namei>
    80004e28:	c92d                	beqz	a0,80004e9a <exec+0xbc>
    80004e2a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	ab4080e7          	jalr	-1356(ra) # 800038e0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e34:	04000713          	li	a4,64
    80004e38:	4681                	li	a3,0
    80004e3a:	e4840613          	addi	a2,s0,-440
    80004e3e:	4581                	li	a1,0
    80004e40:	8526                	mv	a0,s1
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	d52080e7          	jalr	-686(ra) # 80003b94 <readi>
    80004e4a:	04000793          	li	a5,64
    80004e4e:	00f51a63          	bne	a0,a5,80004e62 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e52:	e4842703          	lw	a4,-440(s0)
    80004e56:	464c47b7          	lui	a5,0x464c4
    80004e5a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e5e:	04f70463          	beq	a4,a5,80004ea6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e62:	8526                	mv	a0,s1
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	cde080e7          	jalr	-802(ra) # 80003b42 <iunlockput>
    end_op();
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	4c6080e7          	jalr	1222(ra) # 80004332 <end_op>
  }
  return -1;
    80004e74:	557d                	li	a0,-1
}
    80004e76:	20813083          	ld	ra,520(sp)
    80004e7a:	20013403          	ld	s0,512(sp)
    80004e7e:	74fe                	ld	s1,504(sp)
    80004e80:	795e                	ld	s2,496(sp)
    80004e82:	79be                	ld	s3,488(sp)
    80004e84:	7a1e                	ld	s4,480(sp)
    80004e86:	6afe                	ld	s5,472(sp)
    80004e88:	6b5e                	ld	s6,464(sp)
    80004e8a:	6bbe                	ld	s7,456(sp)
    80004e8c:	6c1e                	ld	s8,448(sp)
    80004e8e:	7cfa                	ld	s9,440(sp)
    80004e90:	7d5a                	ld	s10,432(sp)
    80004e92:	7dba                	ld	s11,424(sp)
    80004e94:	21010113          	addi	sp,sp,528
    80004e98:	8082                	ret
    end_op();
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	498080e7          	jalr	1176(ra) # 80004332 <end_op>
    return -1;
    80004ea2:	557d                	li	a0,-1
    80004ea4:	bfc9                	j	80004e76 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ea6:	854a                	mv	a0,s2
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	bb0080e7          	jalr	-1104(ra) # 80001a58 <proc_pagetable>
    80004eb0:	8baa                	mv	s7,a0
    80004eb2:	d945                	beqz	a0,80004e62 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb4:	e6842983          	lw	s3,-408(s0)
    80004eb8:	e8045783          	lhu	a5,-384(s0)
    80004ebc:	c7ad                	beqz	a5,80004f26 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ebe:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec0:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004ec2:	6c85                	lui	s9,0x1
    80004ec4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ec8:	def43823          	sd	a5,-528(s0)
    80004ecc:	a42d                	j	800050f6 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ece:	00003517          	auipc	a0,0x3
    80004ed2:	7f250513          	addi	a0,a0,2034 # 800086c0 <syscalls+0x290>
    80004ed6:	ffffb097          	auipc	ra,0xffffb
    80004eda:	65a080e7          	jalr	1626(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ede:	8756                	mv	a4,s5
    80004ee0:	012d86bb          	addw	a3,s11,s2
    80004ee4:	4581                	li	a1,0
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	cac080e7          	jalr	-852(ra) # 80003b94 <readi>
    80004ef0:	2501                	sext.w	a0,a0
    80004ef2:	1aaa9963          	bne	s5,a0,800050a4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ef6:	6785                	lui	a5,0x1
    80004ef8:	0127893b          	addw	s2,a5,s2
    80004efc:	77fd                	lui	a5,0xfffff
    80004efe:	01478a3b          	addw	s4,a5,s4
    80004f02:	1f897163          	bgeu	s2,s8,800050e4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f06:	02091593          	slli	a1,s2,0x20
    80004f0a:	9181                	srli	a1,a1,0x20
    80004f0c:	95ea                	add	a1,a1,s10
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	154080e7          	jalr	340(ra) # 80001064 <walkaddr>
    80004f18:	862a                	mv	a2,a0
    if(pa == 0)
    80004f1a:	d955                	beqz	a0,80004ece <exec+0xf0>
      n = PGSIZE;
    80004f1c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f1e:	fd9a70e3          	bgeu	s4,s9,80004ede <exec+0x100>
      n = sz - i;
    80004f22:	8ad2                	mv	s5,s4
    80004f24:	bf6d                	j	80004ede <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f26:	4901                	li	s2,0
  iunlockput(ip);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	c18080e7          	jalr	-1000(ra) # 80003b42 <iunlockput>
  end_op();
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	400080e7          	jalr	1024(ra) # 80004332 <end_op>
  p = myproc();
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	a5a080e7          	jalr	-1446(ra) # 80001994 <myproc>
    80004f42:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f44:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f48:	6785                	lui	a5,0x1
    80004f4a:	17fd                	addi	a5,a5,-1
    80004f4c:	993e                	add	s2,s2,a5
    80004f4e:	757d                	lui	a0,0xfffff
    80004f50:	00a977b3          	and	a5,s2,a0
    80004f54:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f58:	6609                	lui	a2,0x2
    80004f5a:	963e                	add	a2,a2,a5
    80004f5c:	85be                	mv	a1,a5
    80004f5e:	855e                	mv	a0,s7
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	4a6080e7          	jalr	1190(ra) # 80001406 <uvmalloc>
    80004f68:	8b2a                	mv	s6,a0
  ip = 0;
    80004f6a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f6c:	12050c63          	beqz	a0,800050a4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f70:	75f9                	lui	a1,0xffffe
    80004f72:	95aa                	add	a1,a1,a0
    80004f74:	855e                	mv	a0,s7
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	6ae080e7          	jalr	1710(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f7e:	7c7d                	lui	s8,0xfffff
    80004f80:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f82:	e0043783          	ld	a5,-512(s0)
    80004f86:	6388                	ld	a0,0(a5)
    80004f88:	c535                	beqz	a0,80004ff4 <exec+0x216>
    80004f8a:	e8840993          	addi	s3,s0,-376
    80004f8e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f92:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	ec6080e7          	jalr	-314(ra) # 80000e5a <strlen>
    80004f9c:	2505                	addiw	a0,a0,1
    80004f9e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fa2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fa6:	13896363          	bltu	s2,s8,800050cc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004faa:	e0043d83          	ld	s11,-512(s0)
    80004fae:	000dba03          	ld	s4,0(s11)
    80004fb2:	8552                	mv	a0,s4
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	ea6080e7          	jalr	-346(ra) # 80000e5a <strlen>
    80004fbc:	0015069b          	addiw	a3,a0,1
    80004fc0:	8652                	mv	a2,s4
    80004fc2:	85ca                	mv	a1,s2
    80004fc4:	855e                	mv	a0,s7
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	690080e7          	jalr	1680(ra) # 80001656 <copyout>
    80004fce:	10054363          	bltz	a0,800050d4 <exec+0x2f6>
    ustack[argc] = sp;
    80004fd2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fd6:	0485                	addi	s1,s1,1
    80004fd8:	008d8793          	addi	a5,s11,8
    80004fdc:	e0f43023          	sd	a5,-512(s0)
    80004fe0:	008db503          	ld	a0,8(s11)
    80004fe4:	c911                	beqz	a0,80004ff8 <exec+0x21a>
    if(argc >= MAXARG)
    80004fe6:	09a1                	addi	s3,s3,8
    80004fe8:	fb3c96e3          	bne	s9,s3,80004f94 <exec+0x1b6>
  sz = sz1;
    80004fec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff0:	4481                	li	s1,0
    80004ff2:	a84d                	j	800050a4 <exec+0x2c6>
  sp = sz;
    80004ff4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ff8:	00349793          	slli	a5,s1,0x3
    80004ffc:	f9040713          	addi	a4,s0,-112
    80005000:	97ba                	add	a5,a5,a4
    80005002:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80005006:	00148693          	addi	a3,s1,1
    8000500a:	068e                	slli	a3,a3,0x3
    8000500c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005010:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005014:	01897663          	bgeu	s2,s8,80005020 <exec+0x242>
  sz = sz1;
    80005018:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501c:	4481                	li	s1,0
    8000501e:	a059                	j	800050a4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005020:	e8840613          	addi	a2,s0,-376
    80005024:	85ca                	mv	a1,s2
    80005026:	855e                	mv	a0,s7
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	62e080e7          	jalr	1582(ra) # 80001656 <copyout>
    80005030:	0a054663          	bltz	a0,800050dc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005034:	058ab783          	ld	a5,88(s5)
    80005038:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000503c:	df843783          	ld	a5,-520(s0)
    80005040:	0007c703          	lbu	a4,0(a5)
    80005044:	cf11                	beqz	a4,80005060 <exec+0x282>
    80005046:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005048:	02f00693          	li	a3,47
    8000504c:	a029                	j	80005056 <exec+0x278>
  for(last=s=path; *s; s++)
    8000504e:	0785                	addi	a5,a5,1
    80005050:	fff7c703          	lbu	a4,-1(a5)
    80005054:	c711                	beqz	a4,80005060 <exec+0x282>
    if(*s == '/')
    80005056:	fed71ce3          	bne	a4,a3,8000504e <exec+0x270>
      last = s+1;
    8000505a:	def43c23          	sd	a5,-520(s0)
    8000505e:	bfc5                	j	8000504e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005060:	4641                	li	a2,16
    80005062:	df843583          	ld	a1,-520(s0)
    80005066:	158a8513          	addi	a0,s5,344
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	dbe080e7          	jalr	-578(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80005072:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005076:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000507a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000507e:	058ab783          	ld	a5,88(s5)
    80005082:	e6043703          	ld	a4,-416(s0)
    80005086:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005088:	058ab783          	ld	a5,88(s5)
    8000508c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005090:	85ea                	mv	a1,s10
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	a62080e7          	jalr	-1438(ra) # 80001af4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000509a:	0004851b          	sext.w	a0,s1
    8000509e:	bbe1                	j	80004e76 <exec+0x98>
    800050a0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050a4:	e0843583          	ld	a1,-504(s0)
    800050a8:	855e                	mv	a0,s7
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	a4a080e7          	jalr	-1462(ra) # 80001af4 <proc_freepagetable>
  if(ip){
    800050b2:	da0498e3          	bnez	s1,80004e62 <exec+0x84>
  return -1;
    800050b6:	557d                	li	a0,-1
    800050b8:	bb7d                	j	80004e76 <exec+0x98>
    800050ba:	e1243423          	sd	s2,-504(s0)
    800050be:	b7dd                	j	800050a4 <exec+0x2c6>
    800050c0:	e1243423          	sd	s2,-504(s0)
    800050c4:	b7c5                	j	800050a4 <exec+0x2c6>
    800050c6:	e1243423          	sd	s2,-504(s0)
    800050ca:	bfe9                	j	800050a4 <exec+0x2c6>
  sz = sz1;
    800050cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d0:	4481                	li	s1,0
    800050d2:	bfc9                	j	800050a4 <exec+0x2c6>
  sz = sz1;
    800050d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d8:	4481                	li	s1,0
    800050da:	b7e9                	j	800050a4 <exec+0x2c6>
  sz = sz1;
    800050dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050e0:	4481                	li	s1,0
    800050e2:	b7c9                	j	800050a4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050e4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e8:	2b05                	addiw	s6,s6,1
    800050ea:	0389899b          	addiw	s3,s3,56
    800050ee:	e8045783          	lhu	a5,-384(s0)
    800050f2:	e2fb5be3          	bge	s6,a5,80004f28 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050f6:	2981                	sext.w	s3,s3
    800050f8:	03800713          	li	a4,56
    800050fc:	86ce                	mv	a3,s3
    800050fe:	e1040613          	addi	a2,s0,-496
    80005102:	4581                	li	a1,0
    80005104:	8526                	mv	a0,s1
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	a8e080e7          	jalr	-1394(ra) # 80003b94 <readi>
    8000510e:	03800793          	li	a5,56
    80005112:	f8f517e3          	bne	a0,a5,800050a0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005116:	e1042783          	lw	a5,-496(s0)
    8000511a:	4705                	li	a4,1
    8000511c:	fce796e3          	bne	a5,a4,800050e8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005120:	e3843603          	ld	a2,-456(s0)
    80005124:	e3043783          	ld	a5,-464(s0)
    80005128:	f8f669e3          	bltu	a2,a5,800050ba <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000512c:	e2043783          	ld	a5,-480(s0)
    80005130:	963e                	add	a2,a2,a5
    80005132:	f8f667e3          	bltu	a2,a5,800050c0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005136:	85ca                	mv	a1,s2
    80005138:	855e                	mv	a0,s7
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	2cc080e7          	jalr	716(ra) # 80001406 <uvmalloc>
    80005142:	e0a43423          	sd	a0,-504(s0)
    80005146:	d141                	beqz	a0,800050c6 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005148:	e2043d03          	ld	s10,-480(s0)
    8000514c:	df043783          	ld	a5,-528(s0)
    80005150:	00fd77b3          	and	a5,s10,a5
    80005154:	fba1                	bnez	a5,800050a4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005156:	e1842d83          	lw	s11,-488(s0)
    8000515a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000515e:	f80c03e3          	beqz	s8,800050e4 <exec+0x306>
    80005162:	8a62                	mv	s4,s8
    80005164:	4901                	li	s2,0
    80005166:	b345                	j	80004f06 <exec+0x128>

0000000080005168 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005168:	7179                	addi	sp,sp,-48
    8000516a:	f406                	sd	ra,40(sp)
    8000516c:	f022                	sd	s0,32(sp)
    8000516e:	ec26                	sd	s1,24(sp)
    80005170:	e84a                	sd	s2,16(sp)
    80005172:	1800                	addi	s0,sp,48
    80005174:	892e                	mv	s2,a1
    80005176:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005178:	fdc40593          	addi	a1,s0,-36
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	b8e080e7          	jalr	-1138(ra) # 80002d0a <argint>
    80005184:	04054063          	bltz	a0,800051c4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005188:	fdc42703          	lw	a4,-36(s0)
    8000518c:	47bd                	li	a5,15
    8000518e:	02e7ed63          	bltu	a5,a4,800051c8 <argfd+0x60>
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	802080e7          	jalr	-2046(ra) # 80001994 <myproc>
    8000519a:	fdc42703          	lw	a4,-36(s0)
    8000519e:	01a70793          	addi	a5,a4,26
    800051a2:	078e                	slli	a5,a5,0x3
    800051a4:	953e                	add	a0,a0,a5
    800051a6:	611c                	ld	a5,0(a0)
    800051a8:	c395                	beqz	a5,800051cc <argfd+0x64>
    return -1;
  if(pfd)
    800051aa:	00090463          	beqz	s2,800051b2 <argfd+0x4a>
    *pfd = fd;
    800051ae:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051b2:	4501                	li	a0,0
  if(pf)
    800051b4:	c091                	beqz	s1,800051b8 <argfd+0x50>
    *pf = f;
    800051b6:	e09c                	sd	a5,0(s1)
}
    800051b8:	70a2                	ld	ra,40(sp)
    800051ba:	7402                	ld	s0,32(sp)
    800051bc:	64e2                	ld	s1,24(sp)
    800051be:	6942                	ld	s2,16(sp)
    800051c0:	6145                	addi	sp,sp,48
    800051c2:	8082                	ret
    return -1;
    800051c4:	557d                	li	a0,-1
    800051c6:	bfcd                	j	800051b8 <argfd+0x50>
    return -1;
    800051c8:	557d                	li	a0,-1
    800051ca:	b7fd                	j	800051b8 <argfd+0x50>
    800051cc:	557d                	li	a0,-1
    800051ce:	b7ed                	j	800051b8 <argfd+0x50>

00000000800051d0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051d0:	1101                	addi	sp,sp,-32
    800051d2:	ec06                	sd	ra,24(sp)
    800051d4:	e822                	sd	s0,16(sp)
    800051d6:	e426                	sd	s1,8(sp)
    800051d8:	1000                	addi	s0,sp,32
    800051da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	7b8080e7          	jalr	1976(ra) # 80001994 <myproc>
    800051e4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051e6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800051ea:	4501                	li	a0,0
    800051ec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ee:	6398                	ld	a4,0(a5)
    800051f0:	cb19                	beqz	a4,80005206 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051f2:	2505                	addiw	a0,a0,1
    800051f4:	07a1                	addi	a5,a5,8
    800051f6:	fed51ce3          	bne	a0,a3,800051ee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051fa:	557d                	li	a0,-1
}
    800051fc:	60e2                	ld	ra,24(sp)
    800051fe:	6442                	ld	s0,16(sp)
    80005200:	64a2                	ld	s1,8(sp)
    80005202:	6105                	addi	sp,sp,32
    80005204:	8082                	ret
      p->ofile[fd] = f;
    80005206:	01a50793          	addi	a5,a0,26
    8000520a:	078e                	slli	a5,a5,0x3
    8000520c:	963e                	add	a2,a2,a5
    8000520e:	e204                	sd	s1,0(a2)
      return fd;
    80005210:	b7f5                	j	800051fc <fdalloc+0x2c>

0000000080005212 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005212:	715d                	addi	sp,sp,-80
    80005214:	e486                	sd	ra,72(sp)
    80005216:	e0a2                	sd	s0,64(sp)
    80005218:	fc26                	sd	s1,56(sp)
    8000521a:	f84a                	sd	s2,48(sp)
    8000521c:	f44e                	sd	s3,40(sp)
    8000521e:	f052                	sd	s4,32(sp)
    80005220:	ec56                	sd	s5,24(sp)
    80005222:	0880                	addi	s0,sp,80
    80005224:	89ae                	mv	s3,a1
    80005226:	8ab2                	mv	s5,a2
    80005228:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000522a:	fb040593          	addi	a1,s0,-80
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	e86080e7          	jalr	-378(ra) # 800040b4 <nameiparent>
    80005236:	892a                	mv	s2,a0
    80005238:	12050f63          	beqz	a0,80005376 <create+0x164>
    return 0;

  ilock(dp);
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	6a4080e7          	jalr	1700(ra) # 800038e0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005244:	4601                	li	a2,0
    80005246:	fb040593          	addi	a1,s0,-80
    8000524a:	854a                	mv	a0,s2
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	b78080e7          	jalr	-1160(ra) # 80003dc4 <dirlookup>
    80005254:	84aa                	mv	s1,a0
    80005256:	c921                	beqz	a0,800052a6 <create+0x94>
    iunlockput(dp);
    80005258:	854a                	mv	a0,s2
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	8e8080e7          	jalr	-1816(ra) # 80003b42 <iunlockput>
    ilock(ip);
    80005262:	8526                	mv	a0,s1
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	67c080e7          	jalr	1660(ra) # 800038e0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000526c:	2981                	sext.w	s3,s3
    8000526e:	4789                	li	a5,2
    80005270:	02f99463          	bne	s3,a5,80005298 <create+0x86>
    80005274:	0444d783          	lhu	a5,68(s1)
    80005278:	37f9                	addiw	a5,a5,-2
    8000527a:	17c2                	slli	a5,a5,0x30
    8000527c:	93c1                	srli	a5,a5,0x30
    8000527e:	4705                	li	a4,1
    80005280:	00f76c63          	bltu	a4,a5,80005298 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005284:	8526                	mv	a0,s1
    80005286:	60a6                	ld	ra,72(sp)
    80005288:	6406                	ld	s0,64(sp)
    8000528a:	74e2                	ld	s1,56(sp)
    8000528c:	7942                	ld	s2,48(sp)
    8000528e:	79a2                	ld	s3,40(sp)
    80005290:	7a02                	ld	s4,32(sp)
    80005292:	6ae2                	ld	s5,24(sp)
    80005294:	6161                	addi	sp,sp,80
    80005296:	8082                	ret
    iunlockput(ip);
    80005298:	8526                	mv	a0,s1
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	8a8080e7          	jalr	-1880(ra) # 80003b42 <iunlockput>
    return 0;
    800052a2:	4481                	li	s1,0
    800052a4:	b7c5                	j	80005284 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052a6:	85ce                	mv	a1,s3
    800052a8:	00092503          	lw	a0,0(s2)
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	49c080e7          	jalr	1180(ra) # 80003748 <ialloc>
    800052b4:	84aa                	mv	s1,a0
    800052b6:	c529                	beqz	a0,80005300 <create+0xee>
  ilock(ip);
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	628080e7          	jalr	1576(ra) # 800038e0 <ilock>
  ip->major = major;
    800052c0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052c4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052c8:	4785                	li	a5,1
    800052ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052ce:	8526                	mv	a0,s1
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	546080e7          	jalr	1350(ra) # 80003816 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d8:	2981                	sext.w	s3,s3
    800052da:	4785                	li	a5,1
    800052dc:	02f98a63          	beq	s3,a5,80005310 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052e0:	40d0                	lw	a2,4(s1)
    800052e2:	fb040593          	addi	a1,s0,-80
    800052e6:	854a                	mv	a0,s2
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	cec080e7          	jalr	-788(ra) # 80003fd4 <dirlink>
    800052f0:	06054b63          	bltz	a0,80005366 <create+0x154>
  iunlockput(dp);
    800052f4:	854a                	mv	a0,s2
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	84c080e7          	jalr	-1972(ra) # 80003b42 <iunlockput>
  return ip;
    800052fe:	b759                	j	80005284 <create+0x72>
    panic("create: ialloc");
    80005300:	00003517          	auipc	a0,0x3
    80005304:	3e050513          	addi	a0,a0,992 # 800086e0 <syscalls+0x2b0>
    80005308:	ffffb097          	auipc	ra,0xffffb
    8000530c:	228080e7          	jalr	552(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005310:	04a95783          	lhu	a5,74(s2)
    80005314:	2785                	addiw	a5,a5,1
    80005316:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000531a:	854a                	mv	a0,s2
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	4fa080e7          	jalr	1274(ra) # 80003816 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005324:	40d0                	lw	a2,4(s1)
    80005326:	00003597          	auipc	a1,0x3
    8000532a:	3ca58593          	addi	a1,a1,970 # 800086f0 <syscalls+0x2c0>
    8000532e:	8526                	mv	a0,s1
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	ca4080e7          	jalr	-860(ra) # 80003fd4 <dirlink>
    80005338:	00054f63          	bltz	a0,80005356 <create+0x144>
    8000533c:	00492603          	lw	a2,4(s2)
    80005340:	00003597          	auipc	a1,0x3
    80005344:	3b858593          	addi	a1,a1,952 # 800086f8 <syscalls+0x2c8>
    80005348:	8526                	mv	a0,s1
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	c8a080e7          	jalr	-886(ra) # 80003fd4 <dirlink>
    80005352:	f80557e3          	bgez	a0,800052e0 <create+0xce>
      panic("create dots");
    80005356:	00003517          	auipc	a0,0x3
    8000535a:	3aa50513          	addi	a0,a0,938 # 80008700 <syscalls+0x2d0>
    8000535e:	ffffb097          	auipc	ra,0xffffb
    80005362:	1d2080e7          	jalr	466(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005366:	00003517          	auipc	a0,0x3
    8000536a:	3aa50513          	addi	a0,a0,938 # 80008710 <syscalls+0x2e0>
    8000536e:	ffffb097          	auipc	ra,0xffffb
    80005372:	1c2080e7          	jalr	450(ra) # 80000530 <panic>
    return 0;
    80005376:	84aa                	mv	s1,a0
    80005378:	b731                	j	80005284 <create+0x72>

000000008000537a <sys_dup>:
{
    8000537a:	7179                	addi	sp,sp,-48
    8000537c:	f406                	sd	ra,40(sp)
    8000537e:	f022                	sd	s0,32(sp)
    80005380:	ec26                	sd	s1,24(sp)
    80005382:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005384:	fd840613          	addi	a2,s0,-40
    80005388:	4581                	li	a1,0
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	ddc080e7          	jalr	-548(ra) # 80005168 <argfd>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005396:	02054363          	bltz	a0,800053bc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000539a:	fd843503          	ld	a0,-40(s0)
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	e32080e7          	jalr	-462(ra) # 800051d0 <fdalloc>
    800053a6:	84aa                	mv	s1,a0
    return -1;
    800053a8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053aa:	00054963          	bltz	a0,800053bc <sys_dup+0x42>
  filedup(f);
    800053ae:	fd843503          	ld	a0,-40(s0)
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	37a080e7          	jalr	890(ra) # 8000472c <filedup>
  return fd;
    800053ba:	87a6                	mv	a5,s1
}
    800053bc:	853e                	mv	a0,a5
    800053be:	70a2                	ld	ra,40(sp)
    800053c0:	7402                	ld	s0,32(sp)
    800053c2:	64e2                	ld	s1,24(sp)
    800053c4:	6145                	addi	sp,sp,48
    800053c6:	8082                	ret

00000000800053c8 <sys_read>:
{
    800053c8:	7179                	addi	sp,sp,-48
    800053ca:	f406                	sd	ra,40(sp)
    800053cc:	f022                	sd	s0,32(sp)
    800053ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d0:	fe840613          	addi	a2,s0,-24
    800053d4:	4581                	li	a1,0
    800053d6:	4501                	li	a0,0
    800053d8:	00000097          	auipc	ra,0x0
    800053dc:	d90080e7          	jalr	-624(ra) # 80005168 <argfd>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	04054163          	bltz	a0,80005424 <sys_read+0x5c>
    800053e6:	fe440593          	addi	a1,s0,-28
    800053ea:	4509                	li	a0,2
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	91e080e7          	jalr	-1762(ra) # 80002d0a <argint>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	02054763          	bltz	a0,80005424 <sys_read+0x5c>
    800053fa:	fd840593          	addi	a1,s0,-40
    800053fe:	4505                	li	a0,1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	92c080e7          	jalr	-1748(ra) # 80002d2c <argaddr>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540a:	00054d63          	bltz	a0,80005424 <sys_read+0x5c>
  return fileread(f, p, n);
    8000540e:	fe442603          	lw	a2,-28(s0)
    80005412:	fd843583          	ld	a1,-40(s0)
    80005416:	fe843503          	ld	a0,-24(s0)
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	49e080e7          	jalr	1182(ra) # 800048b8 <fileread>
    80005422:	87aa                	mv	a5,a0
}
    80005424:	853e                	mv	a0,a5
    80005426:	70a2                	ld	ra,40(sp)
    80005428:	7402                	ld	s0,32(sp)
    8000542a:	6145                	addi	sp,sp,48
    8000542c:	8082                	ret

000000008000542e <sys_write>:
{
    8000542e:	7179                	addi	sp,sp,-48
    80005430:	f406                	sd	ra,40(sp)
    80005432:	f022                	sd	s0,32(sp)
    80005434:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005436:	fe840613          	addi	a2,s0,-24
    8000543a:	4581                	li	a1,0
    8000543c:	4501                	li	a0,0
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	d2a080e7          	jalr	-726(ra) # 80005168 <argfd>
    return -1;
    80005446:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005448:	04054163          	bltz	a0,8000548a <sys_write+0x5c>
    8000544c:	fe440593          	addi	a1,s0,-28
    80005450:	4509                	li	a0,2
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	8b8080e7          	jalr	-1864(ra) # 80002d0a <argint>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545c:	02054763          	bltz	a0,8000548a <sys_write+0x5c>
    80005460:	fd840593          	addi	a1,s0,-40
    80005464:	4505                	li	a0,1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	8c6080e7          	jalr	-1850(ra) # 80002d2c <argaddr>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005470:	00054d63          	bltz	a0,8000548a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005474:	fe442603          	lw	a2,-28(s0)
    80005478:	fd843583          	ld	a1,-40(s0)
    8000547c:	fe843503          	ld	a0,-24(s0)
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	4fa080e7          	jalr	1274(ra) # 8000497a <filewrite>
    80005488:	87aa                	mv	a5,a0
}
    8000548a:	853e                	mv	a0,a5
    8000548c:	70a2                	ld	ra,40(sp)
    8000548e:	7402                	ld	s0,32(sp)
    80005490:	6145                	addi	sp,sp,48
    80005492:	8082                	ret

0000000080005494 <sys_close>:
{
    80005494:	1101                	addi	sp,sp,-32
    80005496:	ec06                	sd	ra,24(sp)
    80005498:	e822                	sd	s0,16(sp)
    8000549a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000549c:	fe040613          	addi	a2,s0,-32
    800054a0:	fec40593          	addi	a1,s0,-20
    800054a4:	4501                	li	a0,0
    800054a6:	00000097          	auipc	ra,0x0
    800054aa:	cc2080e7          	jalr	-830(ra) # 80005168 <argfd>
    return -1;
    800054ae:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054b0:	02054463          	bltz	a0,800054d8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054b4:	ffffc097          	auipc	ra,0xffffc
    800054b8:	4e0080e7          	jalr	1248(ra) # 80001994 <myproc>
    800054bc:	fec42783          	lw	a5,-20(s0)
    800054c0:	07e9                	addi	a5,a5,26
    800054c2:	078e                	slli	a5,a5,0x3
    800054c4:	97aa                	add	a5,a5,a0
    800054c6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054ca:	fe043503          	ld	a0,-32(s0)
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	2b0080e7          	jalr	688(ra) # 8000477e <fileclose>
  return 0;
    800054d6:	4781                	li	a5,0
}
    800054d8:	853e                	mv	a0,a5
    800054da:	60e2                	ld	ra,24(sp)
    800054dc:	6442                	ld	s0,16(sp)
    800054de:	6105                	addi	sp,sp,32
    800054e0:	8082                	ret

00000000800054e2 <sys_fstat>:
{
    800054e2:	1101                	addi	sp,sp,-32
    800054e4:	ec06                	sd	ra,24(sp)
    800054e6:	e822                	sd	s0,16(sp)
    800054e8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ea:	fe840613          	addi	a2,s0,-24
    800054ee:	4581                	li	a1,0
    800054f0:	4501                	li	a0,0
    800054f2:	00000097          	auipc	ra,0x0
    800054f6:	c76080e7          	jalr	-906(ra) # 80005168 <argfd>
    return -1;
    800054fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fc:	02054563          	bltz	a0,80005526 <sys_fstat+0x44>
    80005500:	fe040593          	addi	a1,s0,-32
    80005504:	4505                	li	a0,1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	826080e7          	jalr	-2010(ra) # 80002d2c <argaddr>
    return -1;
    8000550e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005510:	00054b63          	bltz	a0,80005526 <sys_fstat+0x44>
  return filestat(f, st);
    80005514:	fe043583          	ld	a1,-32(s0)
    80005518:	fe843503          	ld	a0,-24(s0)
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	32a080e7          	jalr	810(ra) # 80004846 <filestat>
    80005524:	87aa                	mv	a5,a0
}
    80005526:	853e                	mv	a0,a5
    80005528:	60e2                	ld	ra,24(sp)
    8000552a:	6442                	ld	s0,16(sp)
    8000552c:	6105                	addi	sp,sp,32
    8000552e:	8082                	ret

0000000080005530 <sys_link>:
{
    80005530:	7169                	addi	sp,sp,-304
    80005532:	f606                	sd	ra,296(sp)
    80005534:	f222                	sd	s0,288(sp)
    80005536:	ee26                	sd	s1,280(sp)
    80005538:	ea4a                	sd	s2,272(sp)
    8000553a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553c:	08000613          	li	a2,128
    80005540:	ed040593          	addi	a1,s0,-304
    80005544:	4501                	li	a0,0
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	808080e7          	jalr	-2040(ra) # 80002d4e <argstr>
    return -1;
    8000554e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005550:	10054e63          	bltz	a0,8000566c <sys_link+0x13c>
    80005554:	08000613          	li	a2,128
    80005558:	f5040593          	addi	a1,s0,-176
    8000555c:	4505                	li	a0,1
    8000555e:	ffffd097          	auipc	ra,0xffffd
    80005562:	7f0080e7          	jalr	2032(ra) # 80002d4e <argstr>
    return -1;
    80005566:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005568:	10054263          	bltz	a0,8000566c <sys_link+0x13c>
  begin_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	d46080e7          	jalr	-698(ra) # 800042b2 <begin_op>
  if((ip = namei(old)) == 0){
    80005574:	ed040513          	addi	a0,s0,-304
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	b1e080e7          	jalr	-1250(ra) # 80004096 <namei>
    80005580:	84aa                	mv	s1,a0
    80005582:	c551                	beqz	a0,8000560e <sys_link+0xde>
  ilock(ip);
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	35c080e7          	jalr	860(ra) # 800038e0 <ilock>
  if(ip->type == T_DIR){
    8000558c:	04449703          	lh	a4,68(s1)
    80005590:	4785                	li	a5,1
    80005592:	08f70463          	beq	a4,a5,8000561a <sys_link+0xea>
  ip->nlink++;
    80005596:	04a4d783          	lhu	a5,74(s1)
    8000559a:	2785                	addiw	a5,a5,1
    8000559c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	274080e7          	jalr	628(ra) # 80003816 <iupdate>
  iunlock(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	3f6080e7          	jalr	1014(ra) # 800039a2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055b4:	fd040593          	addi	a1,s0,-48
    800055b8:	f5040513          	addi	a0,s0,-176
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	af8080e7          	jalr	-1288(ra) # 800040b4 <nameiparent>
    800055c4:	892a                	mv	s2,a0
    800055c6:	c935                	beqz	a0,8000563a <sys_link+0x10a>
  ilock(dp);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	318080e7          	jalr	792(ra) # 800038e0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055d0:	00092703          	lw	a4,0(s2)
    800055d4:	409c                	lw	a5,0(s1)
    800055d6:	04f71d63          	bne	a4,a5,80005630 <sys_link+0x100>
    800055da:	40d0                	lw	a2,4(s1)
    800055dc:	fd040593          	addi	a1,s0,-48
    800055e0:	854a                	mv	a0,s2
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	9f2080e7          	jalr	-1550(ra) # 80003fd4 <dirlink>
    800055ea:	04054363          	bltz	a0,80005630 <sys_link+0x100>
  iunlockput(dp);
    800055ee:	854a                	mv	a0,s2
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	552080e7          	jalr	1362(ra) # 80003b42 <iunlockput>
  iput(ip);
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	4a0080e7          	jalr	1184(ra) # 80003a9a <iput>
  end_op();
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	d30080e7          	jalr	-720(ra) # 80004332 <end_op>
  return 0;
    8000560a:	4781                	li	a5,0
    8000560c:	a085                	j	8000566c <sys_link+0x13c>
    end_op();
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	d24080e7          	jalr	-732(ra) # 80004332 <end_op>
    return -1;
    80005616:	57fd                	li	a5,-1
    80005618:	a891                	j	8000566c <sys_link+0x13c>
    iunlockput(ip);
    8000561a:	8526                	mv	a0,s1
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	526080e7          	jalr	1318(ra) # 80003b42 <iunlockput>
    end_op();
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	d0e080e7          	jalr	-754(ra) # 80004332 <end_op>
    return -1;
    8000562c:	57fd                	li	a5,-1
    8000562e:	a83d                	j	8000566c <sys_link+0x13c>
    iunlockput(dp);
    80005630:	854a                	mv	a0,s2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	510080e7          	jalr	1296(ra) # 80003b42 <iunlockput>
  ilock(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	2a4080e7          	jalr	676(ra) # 800038e0 <ilock>
  ip->nlink--;
    80005644:	04a4d783          	lhu	a5,74(s1)
    80005648:	37fd                	addiw	a5,a5,-1
    8000564a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	1c6080e7          	jalr	454(ra) # 80003816 <iupdate>
  iunlockput(ip);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	4e8080e7          	jalr	1256(ra) # 80003b42 <iunlockput>
  end_op();
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	cd0080e7          	jalr	-816(ra) # 80004332 <end_op>
  return -1;
    8000566a:	57fd                	li	a5,-1
}
    8000566c:	853e                	mv	a0,a5
    8000566e:	70b2                	ld	ra,296(sp)
    80005670:	7412                	ld	s0,288(sp)
    80005672:	64f2                	ld	s1,280(sp)
    80005674:	6952                	ld	s2,272(sp)
    80005676:	6155                	addi	sp,sp,304
    80005678:	8082                	ret

000000008000567a <sys_unlink>:
{
    8000567a:	7151                	addi	sp,sp,-240
    8000567c:	f586                	sd	ra,232(sp)
    8000567e:	f1a2                	sd	s0,224(sp)
    80005680:	eda6                	sd	s1,216(sp)
    80005682:	e9ca                	sd	s2,208(sp)
    80005684:	e5ce                	sd	s3,200(sp)
    80005686:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005688:	08000613          	li	a2,128
    8000568c:	f3040593          	addi	a1,s0,-208
    80005690:	4501                	li	a0,0
    80005692:	ffffd097          	auipc	ra,0xffffd
    80005696:	6bc080e7          	jalr	1724(ra) # 80002d4e <argstr>
    8000569a:	18054163          	bltz	a0,8000581c <sys_unlink+0x1a2>
  begin_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	c14080e7          	jalr	-1004(ra) # 800042b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a6:	fb040593          	addi	a1,s0,-80
    800056aa:	f3040513          	addi	a0,s0,-208
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	a06080e7          	jalr	-1530(ra) # 800040b4 <nameiparent>
    800056b6:	84aa                	mv	s1,a0
    800056b8:	c979                	beqz	a0,8000578e <sys_unlink+0x114>
  ilock(dp);
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	226080e7          	jalr	550(ra) # 800038e0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056c2:	00003597          	auipc	a1,0x3
    800056c6:	02e58593          	addi	a1,a1,46 # 800086f0 <syscalls+0x2c0>
    800056ca:	fb040513          	addi	a0,s0,-80
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	6dc080e7          	jalr	1756(ra) # 80003daa <namecmp>
    800056d6:	14050a63          	beqz	a0,8000582a <sys_unlink+0x1b0>
    800056da:	00003597          	auipc	a1,0x3
    800056de:	01e58593          	addi	a1,a1,30 # 800086f8 <syscalls+0x2c8>
    800056e2:	fb040513          	addi	a0,s0,-80
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	6c4080e7          	jalr	1732(ra) # 80003daa <namecmp>
    800056ee:	12050e63          	beqz	a0,8000582a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056f2:	f2c40613          	addi	a2,s0,-212
    800056f6:	fb040593          	addi	a1,s0,-80
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	6c8080e7          	jalr	1736(ra) # 80003dc4 <dirlookup>
    80005704:	892a                	mv	s2,a0
    80005706:	12050263          	beqz	a0,8000582a <sys_unlink+0x1b0>
  ilock(ip);
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	1d6080e7          	jalr	470(ra) # 800038e0 <ilock>
  if(ip->nlink < 1)
    80005712:	04a91783          	lh	a5,74(s2)
    80005716:	08f05263          	blez	a5,8000579a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000571a:	04491703          	lh	a4,68(s2)
    8000571e:	4785                	li	a5,1
    80005720:	08f70563          	beq	a4,a5,800057aa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005724:	4641                	li	a2,16
    80005726:	4581                	li	a1,0
    80005728:	fc040513          	addi	a0,s0,-64
    8000572c:	ffffb097          	auipc	ra,0xffffb
    80005730:	5a6080e7          	jalr	1446(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005734:	4741                	li	a4,16
    80005736:	f2c42683          	lw	a3,-212(s0)
    8000573a:	fc040613          	addi	a2,s0,-64
    8000573e:	4581                	li	a1,0
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	54a080e7          	jalr	1354(ra) # 80003c8c <writei>
    8000574a:	47c1                	li	a5,16
    8000574c:	0af51563          	bne	a0,a5,800057f6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005750:	04491703          	lh	a4,68(s2)
    80005754:	4785                	li	a5,1
    80005756:	0af70863          	beq	a4,a5,80005806 <sys_unlink+0x18c>
  iunlockput(dp);
    8000575a:	8526                	mv	a0,s1
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	3e6080e7          	jalr	998(ra) # 80003b42 <iunlockput>
  ip->nlink--;
    80005764:	04a95783          	lhu	a5,74(s2)
    80005768:	37fd                	addiw	a5,a5,-1
    8000576a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000576e:	854a                	mv	a0,s2
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	0a6080e7          	jalr	166(ra) # 80003816 <iupdate>
  iunlockput(ip);
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	3c8080e7          	jalr	968(ra) # 80003b42 <iunlockput>
  end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	bb0080e7          	jalr	-1104(ra) # 80004332 <end_op>
  return 0;
    8000578a:	4501                	li	a0,0
    8000578c:	a84d                	j	8000583e <sys_unlink+0x1c4>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	ba4080e7          	jalr	-1116(ra) # 80004332 <end_op>
    return -1;
    80005796:	557d                	li	a0,-1
    80005798:	a05d                	j	8000583e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000579a:	00003517          	auipc	a0,0x3
    8000579e:	f8650513          	addi	a0,a0,-122 # 80008720 <syscalls+0x2f0>
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	d8e080e7          	jalr	-626(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057aa:	04c92703          	lw	a4,76(s2)
    800057ae:	02000793          	li	a5,32
    800057b2:	f6e7f9e3          	bgeu	a5,a4,80005724 <sys_unlink+0xaa>
    800057b6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ba:	4741                	li	a4,16
    800057bc:	86ce                	mv	a3,s3
    800057be:	f1840613          	addi	a2,s0,-232
    800057c2:	4581                	li	a1,0
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	3ce080e7          	jalr	974(ra) # 80003b94 <readi>
    800057ce:	47c1                	li	a5,16
    800057d0:	00f51b63          	bne	a0,a5,800057e6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057d4:	f1845783          	lhu	a5,-232(s0)
    800057d8:	e7a1                	bnez	a5,80005820 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057da:	29c1                	addiw	s3,s3,16
    800057dc:	04c92783          	lw	a5,76(s2)
    800057e0:	fcf9ede3          	bltu	s3,a5,800057ba <sys_unlink+0x140>
    800057e4:	b781                	j	80005724 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e6:	00003517          	auipc	a0,0x3
    800057ea:	f5250513          	addi	a0,a0,-174 # 80008738 <syscalls+0x308>
    800057ee:	ffffb097          	auipc	ra,0xffffb
    800057f2:	d42080e7          	jalr	-702(ra) # 80000530 <panic>
    panic("unlink: writei");
    800057f6:	00003517          	auipc	a0,0x3
    800057fa:	f5a50513          	addi	a0,a0,-166 # 80008750 <syscalls+0x320>
    800057fe:	ffffb097          	auipc	ra,0xffffb
    80005802:	d32080e7          	jalr	-718(ra) # 80000530 <panic>
    dp->nlink--;
    80005806:	04a4d783          	lhu	a5,74(s1)
    8000580a:	37fd                	addiw	a5,a5,-1
    8000580c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	004080e7          	jalr	4(ra) # 80003816 <iupdate>
    8000581a:	b781                	j	8000575a <sys_unlink+0xe0>
    return -1;
    8000581c:	557d                	li	a0,-1
    8000581e:	a005                	j	8000583e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	320080e7          	jalr	800(ra) # 80003b42 <iunlockput>
  iunlockput(dp);
    8000582a:	8526                	mv	a0,s1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	316080e7          	jalr	790(ra) # 80003b42 <iunlockput>
  end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	afe080e7          	jalr	-1282(ra) # 80004332 <end_op>
  return -1;
    8000583c:	557d                	li	a0,-1
}
    8000583e:	70ae                	ld	ra,232(sp)
    80005840:	740e                	ld	s0,224(sp)
    80005842:	64ee                	ld	s1,216(sp)
    80005844:	694e                	ld	s2,208(sp)
    80005846:	69ae                	ld	s3,200(sp)
    80005848:	616d                	addi	sp,sp,240
    8000584a:	8082                	ret

000000008000584c <sys_open>:

uint64
sys_open(void)
{
    8000584c:	7131                	addi	sp,sp,-192
    8000584e:	fd06                	sd	ra,184(sp)
    80005850:	f922                	sd	s0,176(sp)
    80005852:	f526                	sd	s1,168(sp)
    80005854:	f14a                	sd	s2,160(sp)
    80005856:	ed4e                	sd	s3,152(sp)
    80005858:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585a:	08000613          	li	a2,128
    8000585e:	f5040593          	addi	a1,s0,-176
    80005862:	4501                	li	a0,0
    80005864:	ffffd097          	auipc	ra,0xffffd
    80005868:	4ea080e7          	jalr	1258(ra) # 80002d4e <argstr>
    return -1;
    8000586c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000586e:	0c054163          	bltz	a0,80005930 <sys_open+0xe4>
    80005872:	f4c40593          	addi	a1,s0,-180
    80005876:	4505                	li	a0,1
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	492080e7          	jalr	1170(ra) # 80002d0a <argint>
    80005880:	0a054863          	bltz	a0,80005930 <sys_open+0xe4>

  begin_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	a2e080e7          	jalr	-1490(ra) # 800042b2 <begin_op>

  if(omode & O_CREATE){
    8000588c:	f4c42783          	lw	a5,-180(s0)
    80005890:	2007f793          	andi	a5,a5,512
    80005894:	cbdd                	beqz	a5,8000594a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005896:	4681                	li	a3,0
    80005898:	4601                	li	a2,0
    8000589a:	4589                	li	a1,2
    8000589c:	f5040513          	addi	a0,s0,-176
    800058a0:	00000097          	auipc	ra,0x0
    800058a4:	972080e7          	jalr	-1678(ra) # 80005212 <create>
    800058a8:	892a                	mv	s2,a0
    if(ip == 0){
    800058aa:	c959                	beqz	a0,80005940 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058ac:	04491703          	lh	a4,68(s2)
    800058b0:	478d                	li	a5,3
    800058b2:	00f71763          	bne	a4,a5,800058c0 <sys_open+0x74>
    800058b6:	04695703          	lhu	a4,70(s2)
    800058ba:	47a5                	li	a5,9
    800058bc:	0ce7ec63          	bltu	a5,a4,80005994 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	e02080e7          	jalr	-510(ra) # 800046c2 <filealloc>
    800058c8:	89aa                	mv	s3,a0
    800058ca:	10050263          	beqz	a0,800059ce <sys_open+0x182>
    800058ce:	00000097          	auipc	ra,0x0
    800058d2:	902080e7          	jalr	-1790(ra) # 800051d0 <fdalloc>
    800058d6:	84aa                	mv	s1,a0
    800058d8:	0e054663          	bltz	a0,800059c4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058dc:	04491703          	lh	a4,68(s2)
    800058e0:	478d                	li	a5,3
    800058e2:	0cf70463          	beq	a4,a5,800059aa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058e6:	4789                	li	a5,2
    800058e8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058ec:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058f0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058f4:	f4c42783          	lw	a5,-180(s0)
    800058f8:	0017c713          	xori	a4,a5,1
    800058fc:	8b05                	andi	a4,a4,1
    800058fe:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005902:	0037f713          	andi	a4,a5,3
    80005906:	00e03733          	snez	a4,a4
    8000590a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000590e:	4007f793          	andi	a5,a5,1024
    80005912:	c791                	beqz	a5,8000591e <sys_open+0xd2>
    80005914:	04491703          	lh	a4,68(s2)
    80005918:	4789                	li	a5,2
    8000591a:	08f70f63          	beq	a4,a5,800059b8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000591e:	854a                	mv	a0,s2
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	082080e7          	jalr	130(ra) # 800039a2 <iunlock>
  end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	a0a080e7          	jalr	-1526(ra) # 80004332 <end_op>

  return fd;
}
    80005930:	8526                	mv	a0,s1
    80005932:	70ea                	ld	ra,184(sp)
    80005934:	744a                	ld	s0,176(sp)
    80005936:	74aa                	ld	s1,168(sp)
    80005938:	790a                	ld	s2,160(sp)
    8000593a:	69ea                	ld	s3,152(sp)
    8000593c:	6129                	addi	sp,sp,192
    8000593e:	8082                	ret
      end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	9f2080e7          	jalr	-1550(ra) # 80004332 <end_op>
      return -1;
    80005948:	b7e5                	j	80005930 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000594a:	f5040513          	addi	a0,s0,-176
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	748080e7          	jalr	1864(ra) # 80004096 <namei>
    80005956:	892a                	mv	s2,a0
    80005958:	c905                	beqz	a0,80005988 <sys_open+0x13c>
    ilock(ip);
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	f86080e7          	jalr	-122(ra) # 800038e0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005962:	04491703          	lh	a4,68(s2)
    80005966:	4785                	li	a5,1
    80005968:	f4f712e3          	bne	a4,a5,800058ac <sys_open+0x60>
    8000596c:	f4c42783          	lw	a5,-180(s0)
    80005970:	dba1                	beqz	a5,800058c0 <sys_open+0x74>
      iunlockput(ip);
    80005972:	854a                	mv	a0,s2
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	1ce080e7          	jalr	462(ra) # 80003b42 <iunlockput>
      end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	9b6080e7          	jalr	-1610(ra) # 80004332 <end_op>
      return -1;
    80005984:	54fd                	li	s1,-1
    80005986:	b76d                	j	80005930 <sys_open+0xe4>
      end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	9aa080e7          	jalr	-1622(ra) # 80004332 <end_op>
      return -1;
    80005990:	54fd                	li	s1,-1
    80005992:	bf79                	j	80005930 <sys_open+0xe4>
    iunlockput(ip);
    80005994:	854a                	mv	a0,s2
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	1ac080e7          	jalr	428(ra) # 80003b42 <iunlockput>
    end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	994080e7          	jalr	-1644(ra) # 80004332 <end_op>
    return -1;
    800059a6:	54fd                	li	s1,-1
    800059a8:	b761                	j	80005930 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059aa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059ae:	04691783          	lh	a5,70(s2)
    800059b2:	02f99223          	sh	a5,36(s3)
    800059b6:	bf2d                	j	800058f0 <sys_open+0xa4>
    itrunc(ip);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	034080e7          	jalr	52(ra) # 800039ee <itrunc>
    800059c2:	bfb1                	j	8000591e <sys_open+0xd2>
      fileclose(f);
    800059c4:	854e                	mv	a0,s3
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	db8080e7          	jalr	-584(ra) # 8000477e <fileclose>
    iunlockput(ip);
    800059ce:	854a                	mv	a0,s2
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	172080e7          	jalr	370(ra) # 80003b42 <iunlockput>
    end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	95a080e7          	jalr	-1702(ra) # 80004332 <end_op>
    return -1;
    800059e0:	54fd                	li	s1,-1
    800059e2:	b7b9                	j	80005930 <sys_open+0xe4>

00000000800059e4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059e4:	7175                	addi	sp,sp,-144
    800059e6:	e506                	sd	ra,136(sp)
    800059e8:	e122                	sd	s0,128(sp)
    800059ea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	8c6080e7          	jalr	-1850(ra) # 800042b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059f4:	08000613          	li	a2,128
    800059f8:	f7040593          	addi	a1,s0,-144
    800059fc:	4501                	li	a0,0
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	350080e7          	jalr	848(ra) # 80002d4e <argstr>
    80005a06:	02054963          	bltz	a0,80005a38 <sys_mkdir+0x54>
    80005a0a:	4681                	li	a3,0
    80005a0c:	4601                	li	a2,0
    80005a0e:	4585                	li	a1,1
    80005a10:	f7040513          	addi	a0,s0,-144
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	7fe080e7          	jalr	2046(ra) # 80005212 <create>
    80005a1c:	cd11                	beqz	a0,80005a38 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	124080e7          	jalr	292(ra) # 80003b42 <iunlockput>
  end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	90c080e7          	jalr	-1780(ra) # 80004332 <end_op>
  return 0;
    80005a2e:	4501                	li	a0,0
}
    80005a30:	60aa                	ld	ra,136(sp)
    80005a32:	640a                	ld	s0,128(sp)
    80005a34:	6149                	addi	sp,sp,144
    80005a36:	8082                	ret
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	8fa080e7          	jalr	-1798(ra) # 80004332 <end_op>
    return -1;
    80005a40:	557d                	li	a0,-1
    80005a42:	b7fd                	j	80005a30 <sys_mkdir+0x4c>

0000000080005a44 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a44:	7135                	addi	sp,sp,-160
    80005a46:	ed06                	sd	ra,152(sp)
    80005a48:	e922                	sd	s0,144(sp)
    80005a4a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	866080e7          	jalr	-1946(ra) # 800042b2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a54:	08000613          	li	a2,128
    80005a58:	f7040593          	addi	a1,s0,-144
    80005a5c:	4501                	li	a0,0
    80005a5e:	ffffd097          	auipc	ra,0xffffd
    80005a62:	2f0080e7          	jalr	752(ra) # 80002d4e <argstr>
    80005a66:	04054a63          	bltz	a0,80005aba <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a6a:	f6c40593          	addi	a1,s0,-148
    80005a6e:	4505                	li	a0,1
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	29a080e7          	jalr	666(ra) # 80002d0a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a78:	04054163          	bltz	a0,80005aba <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a7c:	f6840593          	addi	a1,s0,-152
    80005a80:	4509                	li	a0,2
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	288080e7          	jalr	648(ra) # 80002d0a <argint>
     argint(1, &major) < 0 ||
    80005a8a:	02054863          	bltz	a0,80005aba <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a8e:	f6841683          	lh	a3,-152(s0)
    80005a92:	f6c41603          	lh	a2,-148(s0)
    80005a96:	458d                	li	a1,3
    80005a98:	f7040513          	addi	a0,s0,-144
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	776080e7          	jalr	1910(ra) # 80005212 <create>
     argint(2, &minor) < 0 ||
    80005aa4:	c919                	beqz	a0,80005aba <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	09c080e7          	jalr	156(ra) # 80003b42 <iunlockput>
  end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	884080e7          	jalr	-1916(ra) # 80004332 <end_op>
  return 0;
    80005ab6:	4501                	li	a0,0
    80005ab8:	a031                	j	80005ac4 <sys_mknod+0x80>
    end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	878080e7          	jalr	-1928(ra) # 80004332 <end_op>
    return -1;
    80005ac2:	557d                	li	a0,-1
}
    80005ac4:	60ea                	ld	ra,152(sp)
    80005ac6:	644a                	ld	s0,144(sp)
    80005ac8:	610d                	addi	sp,sp,160
    80005aca:	8082                	ret

0000000080005acc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005acc:	7135                	addi	sp,sp,-160
    80005ace:	ed06                	sd	ra,152(sp)
    80005ad0:	e922                	sd	s0,144(sp)
    80005ad2:	e526                	sd	s1,136(sp)
    80005ad4:	e14a                	sd	s2,128(sp)
    80005ad6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ad8:	ffffc097          	auipc	ra,0xffffc
    80005adc:	ebc080e7          	jalr	-324(ra) # 80001994 <myproc>
    80005ae0:	892a                	mv	s2,a0
  
  begin_op();
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	7d0080e7          	jalr	2000(ra) # 800042b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005aea:	08000613          	li	a2,128
    80005aee:	f6040593          	addi	a1,s0,-160
    80005af2:	4501                	li	a0,0
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	25a080e7          	jalr	602(ra) # 80002d4e <argstr>
    80005afc:	04054b63          	bltz	a0,80005b52 <sys_chdir+0x86>
    80005b00:	f6040513          	addi	a0,s0,-160
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	592080e7          	jalr	1426(ra) # 80004096 <namei>
    80005b0c:	84aa                	mv	s1,a0
    80005b0e:	c131                	beqz	a0,80005b52 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	dd0080e7          	jalr	-560(ra) # 800038e0 <ilock>
  if(ip->type != T_DIR){
    80005b18:	04449703          	lh	a4,68(s1)
    80005b1c:	4785                	li	a5,1
    80005b1e:	04f71063          	bne	a4,a5,80005b5e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	e7e080e7          	jalr	-386(ra) # 800039a2 <iunlock>
  iput(p->cwd);
    80005b2c:	15093503          	ld	a0,336(s2)
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	f6a080e7          	jalr	-150(ra) # 80003a9a <iput>
  end_op();
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	7fa080e7          	jalr	2042(ra) # 80004332 <end_op>
  p->cwd = ip;
    80005b40:	14993823          	sd	s1,336(s2)
  return 0;
    80005b44:	4501                	li	a0,0
}
    80005b46:	60ea                	ld	ra,152(sp)
    80005b48:	644a                	ld	s0,144(sp)
    80005b4a:	64aa                	ld	s1,136(sp)
    80005b4c:	690a                	ld	s2,128(sp)
    80005b4e:	610d                	addi	sp,sp,160
    80005b50:	8082                	ret
    end_op();
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	7e0080e7          	jalr	2016(ra) # 80004332 <end_op>
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	b7ed                	j	80005b46 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	fe2080e7          	jalr	-30(ra) # 80003b42 <iunlockput>
    end_op();
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	7ca080e7          	jalr	1994(ra) # 80004332 <end_op>
    return -1;
    80005b70:	557d                	li	a0,-1
    80005b72:	bfd1                	j	80005b46 <sys_chdir+0x7a>

0000000080005b74 <sys_exec>:

uint64
sys_exec(void)
{
    80005b74:	7145                	addi	sp,sp,-464
    80005b76:	e786                	sd	ra,456(sp)
    80005b78:	e3a2                	sd	s0,448(sp)
    80005b7a:	ff26                	sd	s1,440(sp)
    80005b7c:	fb4a                	sd	s2,432(sp)
    80005b7e:	f74e                	sd	s3,424(sp)
    80005b80:	f352                	sd	s4,416(sp)
    80005b82:	ef56                	sd	s5,408(sp)
    80005b84:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b86:	08000613          	li	a2,128
    80005b8a:	f4040593          	addi	a1,s0,-192
    80005b8e:	4501                	li	a0,0
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	1be080e7          	jalr	446(ra) # 80002d4e <argstr>
    return -1;
    80005b98:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b9a:	0c054a63          	bltz	a0,80005c6e <sys_exec+0xfa>
    80005b9e:	e3840593          	addi	a1,s0,-456
    80005ba2:	4505                	li	a0,1
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	188080e7          	jalr	392(ra) # 80002d2c <argaddr>
    80005bac:	0c054163          	bltz	a0,80005c6e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bb0:	10000613          	li	a2,256
    80005bb4:	4581                	li	a1,0
    80005bb6:	e4040513          	addi	a0,s0,-448
    80005bba:	ffffb097          	auipc	ra,0xffffb
    80005bbe:	118080e7          	jalr	280(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bc2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bc6:	89a6                	mv	s3,s1
    80005bc8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bca:	02000a13          	li	s4,32
    80005bce:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bd2:	00391513          	slli	a0,s2,0x3
    80005bd6:	e3040593          	addi	a1,s0,-464
    80005bda:	e3843783          	ld	a5,-456(s0)
    80005bde:	953e                	add	a0,a0,a5
    80005be0:	ffffd097          	auipc	ra,0xffffd
    80005be4:	090080e7          	jalr	144(ra) # 80002c70 <fetchaddr>
    80005be8:	02054a63          	bltz	a0,80005c1c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bec:	e3043783          	ld	a5,-464(s0)
    80005bf0:	c3b9                	beqz	a5,80005c36 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bf2:	ffffb097          	auipc	ra,0xffffb
    80005bf6:	ef4080e7          	jalr	-268(ra) # 80000ae6 <kalloc>
    80005bfa:	85aa                	mv	a1,a0
    80005bfc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c00:	cd11                	beqz	a0,80005c1c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c02:	6605                	lui	a2,0x1
    80005c04:	e3043503          	ld	a0,-464(s0)
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	0ba080e7          	jalr	186(ra) # 80002cc2 <fetchstr>
    80005c10:	00054663          	bltz	a0,80005c1c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c14:	0905                	addi	s2,s2,1
    80005c16:	09a1                	addi	s3,s3,8
    80005c18:	fb491be3          	bne	s2,s4,80005bce <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	10048913          	addi	s2,s1,256
    80005c20:	6088                	ld	a0,0(s1)
    80005c22:	c529                	beqz	a0,80005c6c <sys_exec+0xf8>
    kfree(argv[i]);
    80005c24:	ffffb097          	auipc	ra,0xffffb
    80005c28:	dc6080e7          	jalr	-570(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2c:	04a1                	addi	s1,s1,8
    80005c2e:	ff2499e3          	bne	s1,s2,80005c20 <sys_exec+0xac>
  return -1;
    80005c32:	597d                	li	s2,-1
    80005c34:	a82d                	j	80005c6e <sys_exec+0xfa>
      argv[i] = 0;
    80005c36:	0a8e                	slli	s5,s5,0x3
    80005c38:	fc040793          	addi	a5,s0,-64
    80005c3c:	9abe                	add	s5,s5,a5
    80005c3e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c42:	e4040593          	addi	a1,s0,-448
    80005c46:	f4040513          	addi	a0,s0,-192
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	194080e7          	jalr	404(ra) # 80004dde <exec>
    80005c52:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	10048993          	addi	s3,s1,256
    80005c58:	6088                	ld	a0,0(s1)
    80005c5a:	c911                	beqz	a0,80005c6e <sys_exec+0xfa>
    kfree(argv[i]);
    80005c5c:	ffffb097          	auipc	ra,0xffffb
    80005c60:	d8e080e7          	jalr	-626(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c64:	04a1                	addi	s1,s1,8
    80005c66:	ff3499e3          	bne	s1,s3,80005c58 <sys_exec+0xe4>
    80005c6a:	a011                	j	80005c6e <sys_exec+0xfa>
  return -1;
    80005c6c:	597d                	li	s2,-1
}
    80005c6e:	854a                	mv	a0,s2
    80005c70:	60be                	ld	ra,456(sp)
    80005c72:	641e                	ld	s0,448(sp)
    80005c74:	74fa                	ld	s1,440(sp)
    80005c76:	795a                	ld	s2,432(sp)
    80005c78:	79ba                	ld	s3,424(sp)
    80005c7a:	7a1a                	ld	s4,416(sp)
    80005c7c:	6afa                	ld	s5,408(sp)
    80005c7e:	6179                	addi	sp,sp,464
    80005c80:	8082                	ret

0000000080005c82 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c82:	7139                	addi	sp,sp,-64
    80005c84:	fc06                	sd	ra,56(sp)
    80005c86:	f822                	sd	s0,48(sp)
    80005c88:	f426                	sd	s1,40(sp)
    80005c8a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c8c:	ffffc097          	auipc	ra,0xffffc
    80005c90:	d08080e7          	jalr	-760(ra) # 80001994 <myproc>
    80005c94:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c96:	fd840593          	addi	a1,s0,-40
    80005c9a:	4501                	li	a0,0
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	090080e7          	jalr	144(ra) # 80002d2c <argaddr>
    return -1;
    80005ca4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ca6:	0e054063          	bltz	a0,80005d86 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005caa:	fc840593          	addi	a1,s0,-56
    80005cae:	fd040513          	addi	a0,s0,-48
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	dfc080e7          	jalr	-516(ra) # 80004aae <pipealloc>
    return -1;
    80005cba:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cbc:	0c054563          	bltz	a0,80005d86 <sys_pipe+0x104>
  fd0 = -1;
    80005cc0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cc4:	fd043503          	ld	a0,-48(s0)
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	508080e7          	jalr	1288(ra) # 800051d0 <fdalloc>
    80005cd0:	fca42223          	sw	a0,-60(s0)
    80005cd4:	08054c63          	bltz	a0,80005d6c <sys_pipe+0xea>
    80005cd8:	fc843503          	ld	a0,-56(s0)
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	4f4080e7          	jalr	1268(ra) # 800051d0 <fdalloc>
    80005ce4:	fca42023          	sw	a0,-64(s0)
    80005ce8:	06054863          	bltz	a0,80005d58 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cec:	4691                	li	a3,4
    80005cee:	fc440613          	addi	a2,s0,-60
    80005cf2:	fd843583          	ld	a1,-40(s0)
    80005cf6:	68a8                	ld	a0,80(s1)
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	95e080e7          	jalr	-1698(ra) # 80001656 <copyout>
    80005d00:	02054063          	bltz	a0,80005d20 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d04:	4691                	li	a3,4
    80005d06:	fc040613          	addi	a2,s0,-64
    80005d0a:	fd843583          	ld	a1,-40(s0)
    80005d0e:	0591                	addi	a1,a1,4
    80005d10:	68a8                	ld	a0,80(s1)
    80005d12:	ffffc097          	auipc	ra,0xffffc
    80005d16:	944080e7          	jalr	-1724(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d1a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d1c:	06055563          	bgez	a0,80005d86 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d20:	fc442783          	lw	a5,-60(s0)
    80005d24:	07e9                	addi	a5,a5,26
    80005d26:	078e                	slli	a5,a5,0x3
    80005d28:	97a6                	add	a5,a5,s1
    80005d2a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d2e:	fc042503          	lw	a0,-64(s0)
    80005d32:	0569                	addi	a0,a0,26
    80005d34:	050e                	slli	a0,a0,0x3
    80005d36:	9526                	add	a0,a0,s1
    80005d38:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d3c:	fd043503          	ld	a0,-48(s0)
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	a3e080e7          	jalr	-1474(ra) # 8000477e <fileclose>
    fileclose(wf);
    80005d48:	fc843503          	ld	a0,-56(s0)
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	a32080e7          	jalr	-1486(ra) # 8000477e <fileclose>
    return -1;
    80005d54:	57fd                	li	a5,-1
    80005d56:	a805                	j	80005d86 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d58:	fc442783          	lw	a5,-60(s0)
    80005d5c:	0007c863          	bltz	a5,80005d6c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d60:	01a78513          	addi	a0,a5,26
    80005d64:	050e                	slli	a0,a0,0x3
    80005d66:	9526                	add	a0,a0,s1
    80005d68:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d6c:	fd043503          	ld	a0,-48(s0)
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	a0e080e7          	jalr	-1522(ra) # 8000477e <fileclose>
    fileclose(wf);
    80005d78:	fc843503          	ld	a0,-56(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	a02080e7          	jalr	-1534(ra) # 8000477e <fileclose>
    return -1;
    80005d84:	57fd                	li	a5,-1
}
    80005d86:	853e                	mv	a0,a5
    80005d88:	70e2                	ld	ra,56(sp)
    80005d8a:	7442                	ld	s0,48(sp)
    80005d8c:	74a2                	ld	s1,40(sp)
    80005d8e:	6121                	addi	sp,sp,64
    80005d90:	8082                	ret
	...

0000000080005da0 <kernelvec>:
    80005da0:	7111                	addi	sp,sp,-256
    80005da2:	e006                	sd	ra,0(sp)
    80005da4:	e40a                	sd	sp,8(sp)
    80005da6:	e80e                	sd	gp,16(sp)
    80005da8:	ec12                	sd	tp,24(sp)
    80005daa:	f016                	sd	t0,32(sp)
    80005dac:	f41a                	sd	t1,40(sp)
    80005dae:	f81e                	sd	t2,48(sp)
    80005db0:	fc22                	sd	s0,56(sp)
    80005db2:	e0a6                	sd	s1,64(sp)
    80005db4:	e4aa                	sd	a0,72(sp)
    80005db6:	e8ae                	sd	a1,80(sp)
    80005db8:	ecb2                	sd	a2,88(sp)
    80005dba:	f0b6                	sd	a3,96(sp)
    80005dbc:	f4ba                	sd	a4,104(sp)
    80005dbe:	f8be                	sd	a5,112(sp)
    80005dc0:	fcc2                	sd	a6,120(sp)
    80005dc2:	e146                	sd	a7,128(sp)
    80005dc4:	e54a                	sd	s2,136(sp)
    80005dc6:	e94e                	sd	s3,144(sp)
    80005dc8:	ed52                	sd	s4,152(sp)
    80005dca:	f156                	sd	s5,160(sp)
    80005dcc:	f55a                	sd	s6,168(sp)
    80005dce:	f95e                	sd	s7,176(sp)
    80005dd0:	fd62                	sd	s8,184(sp)
    80005dd2:	e1e6                	sd	s9,192(sp)
    80005dd4:	e5ea                	sd	s10,200(sp)
    80005dd6:	e9ee                	sd	s11,208(sp)
    80005dd8:	edf2                	sd	t3,216(sp)
    80005dda:	f1f6                	sd	t4,224(sp)
    80005ddc:	f5fa                	sd	t5,232(sp)
    80005dde:	f9fe                	sd	t6,240(sp)
    80005de0:	d5dfc0ef          	jal	ra,80002b3c <kerneltrap>
    80005de4:	6082                	ld	ra,0(sp)
    80005de6:	6122                	ld	sp,8(sp)
    80005de8:	61c2                	ld	gp,16(sp)
    80005dea:	7282                	ld	t0,32(sp)
    80005dec:	7322                	ld	t1,40(sp)
    80005dee:	73c2                	ld	t2,48(sp)
    80005df0:	7462                	ld	s0,56(sp)
    80005df2:	6486                	ld	s1,64(sp)
    80005df4:	6526                	ld	a0,72(sp)
    80005df6:	65c6                	ld	a1,80(sp)
    80005df8:	6666                	ld	a2,88(sp)
    80005dfa:	7686                	ld	a3,96(sp)
    80005dfc:	7726                	ld	a4,104(sp)
    80005dfe:	77c6                	ld	a5,112(sp)
    80005e00:	7866                	ld	a6,120(sp)
    80005e02:	688a                	ld	a7,128(sp)
    80005e04:	692a                	ld	s2,136(sp)
    80005e06:	69ca                	ld	s3,144(sp)
    80005e08:	6a6a                	ld	s4,152(sp)
    80005e0a:	7a8a                	ld	s5,160(sp)
    80005e0c:	7b2a                	ld	s6,168(sp)
    80005e0e:	7bca                	ld	s7,176(sp)
    80005e10:	7c6a                	ld	s8,184(sp)
    80005e12:	6c8e                	ld	s9,192(sp)
    80005e14:	6d2e                	ld	s10,200(sp)
    80005e16:	6dce                	ld	s11,208(sp)
    80005e18:	6e6e                	ld	t3,216(sp)
    80005e1a:	7e8e                	ld	t4,224(sp)
    80005e1c:	7f2e                	ld	t5,232(sp)
    80005e1e:	7fce                	ld	t6,240(sp)
    80005e20:	6111                	addi	sp,sp,256
    80005e22:	10200073          	sret
    80005e26:	00000013          	nop
    80005e2a:	00000013          	nop
    80005e2e:	0001                	nop

0000000080005e30 <timervec>:
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	e10c                	sd	a1,0(a0)
    80005e36:	e510                	sd	a2,8(a0)
    80005e38:	e914                	sd	a3,16(a0)
    80005e3a:	6d0c                	ld	a1,24(a0)
    80005e3c:	7110                	ld	a2,32(a0)
    80005e3e:	6194                	ld	a3,0(a1)
    80005e40:	96b2                	add	a3,a3,a2
    80005e42:	e194                	sd	a3,0(a1)
    80005e44:	4589                	li	a1,2
    80005e46:	14459073          	csrw	sip,a1
    80005e4a:	6914                	ld	a3,16(a0)
    80005e4c:	6510                	ld	a2,8(a0)
    80005e4e:	610c                	ld	a1,0(a0)
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	30200073          	mret
	...

0000000080005e5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e5a:	1141                	addi	sp,sp,-16
    80005e5c:	e422                	sd	s0,8(sp)
    80005e5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e60:	0c0007b7          	lui	a5,0xc000
    80005e64:	4705                	li	a4,1
    80005e66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e68:	c3d8                	sw	a4,4(a5)
}
    80005e6a:	6422                	ld	s0,8(sp)
    80005e6c:	0141                	addi	sp,sp,16
    80005e6e:	8082                	ret

0000000080005e70 <plicinithart>:

void
plicinithart(void)
{
    80005e70:	1141                	addi	sp,sp,-16
    80005e72:	e406                	sd	ra,8(sp)
    80005e74:	e022                	sd	s0,0(sp)
    80005e76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	af0080e7          	jalr	-1296(ra) # 80001968 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e80:	0085171b          	slliw	a4,a0,0x8
    80005e84:	0c0027b7          	lui	a5,0xc002
    80005e88:	97ba                	add	a5,a5,a4
    80005e8a:	40200713          	li	a4,1026
    80005e8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e92:	00d5151b          	slliw	a0,a0,0xd
    80005e96:	0c2017b7          	lui	a5,0xc201
    80005e9a:	953e                	add	a0,a0,a5
    80005e9c:	00052023          	sw	zero,0(a0)
}
    80005ea0:	60a2                	ld	ra,8(sp)
    80005ea2:	6402                	ld	s0,0(sp)
    80005ea4:	0141                	addi	sp,sp,16
    80005ea6:	8082                	ret

0000000080005ea8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ea8:	1141                	addi	sp,sp,-16
    80005eaa:	e406                	sd	ra,8(sp)
    80005eac:	e022                	sd	s0,0(sp)
    80005eae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005eb0:	ffffc097          	auipc	ra,0xffffc
    80005eb4:	ab8080e7          	jalr	-1352(ra) # 80001968 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005eb8:	00d5179b          	slliw	a5,a0,0xd
    80005ebc:	0c201537          	lui	a0,0xc201
    80005ec0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ec2:	4148                	lw	a0,4(a0)
    80005ec4:	60a2                	ld	ra,8(sp)
    80005ec6:	6402                	ld	s0,0(sp)
    80005ec8:	0141                	addi	sp,sp,16
    80005eca:	8082                	ret

0000000080005ecc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ecc:	1101                	addi	sp,sp,-32
    80005ece:	ec06                	sd	ra,24(sp)
    80005ed0:	e822                	sd	s0,16(sp)
    80005ed2:	e426                	sd	s1,8(sp)
    80005ed4:	1000                	addi	s0,sp,32
    80005ed6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ed8:	ffffc097          	auipc	ra,0xffffc
    80005edc:	a90080e7          	jalr	-1392(ra) # 80001968 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ee0:	00d5151b          	slliw	a0,a0,0xd
    80005ee4:	0c2017b7          	lui	a5,0xc201
    80005ee8:	97aa                	add	a5,a5,a0
    80005eea:	c3c4                	sw	s1,4(a5)
}
    80005eec:	60e2                	ld	ra,24(sp)
    80005eee:	6442                	ld	s0,16(sp)
    80005ef0:	64a2                	ld	s1,8(sp)
    80005ef2:	6105                	addi	sp,sp,32
    80005ef4:	8082                	ret

0000000080005ef6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ef6:	1141                	addi	sp,sp,-16
    80005ef8:	e406                	sd	ra,8(sp)
    80005efa:	e022                	sd	s0,0(sp)
    80005efc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005efe:	479d                	li	a5,7
    80005f00:	06a7c963          	blt	a5,a0,80005f72 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f04:	0001d797          	auipc	a5,0x1d
    80005f08:	0fc78793          	addi	a5,a5,252 # 80023000 <disk>
    80005f0c:	00a78733          	add	a4,a5,a0
    80005f10:	6789                	lui	a5,0x2
    80005f12:	97ba                	add	a5,a5,a4
    80005f14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f18:	e7ad                	bnez	a5,80005f82 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f1a:	00451793          	slli	a5,a0,0x4
    80005f1e:	0001f717          	auipc	a4,0x1f
    80005f22:	0e270713          	addi	a4,a4,226 # 80025000 <disk+0x2000>
    80005f26:	6314                	ld	a3,0(a4)
    80005f28:	96be                	add	a3,a3,a5
    80005f2a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f2e:	6314                	ld	a3,0(a4)
    80005f30:	96be                	add	a3,a3,a5
    80005f32:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f36:	6314                	ld	a3,0(a4)
    80005f38:	96be                	add	a3,a3,a5
    80005f3a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f3e:	6318                	ld	a4,0(a4)
    80005f40:	97ba                	add	a5,a5,a4
    80005f42:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f46:	0001d797          	auipc	a5,0x1d
    80005f4a:	0ba78793          	addi	a5,a5,186 # 80023000 <disk>
    80005f4e:	97aa                	add	a5,a5,a0
    80005f50:	6509                	lui	a0,0x2
    80005f52:	953e                	add	a0,a0,a5
    80005f54:	4785                	li	a5,1
    80005f56:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f5a:	0001f517          	auipc	a0,0x1f
    80005f5e:	0be50513          	addi	a0,a0,190 # 80025018 <disk+0x2018>
    80005f62:	ffffc097          	auipc	ra,0xffffc
    80005f66:	290080e7          	jalr	656(ra) # 800021f2 <wakeup>
}
    80005f6a:	60a2                	ld	ra,8(sp)
    80005f6c:	6402                	ld	s0,0(sp)
    80005f6e:	0141                	addi	sp,sp,16
    80005f70:	8082                	ret
    panic("free_desc 1");
    80005f72:	00002517          	auipc	a0,0x2
    80005f76:	7ee50513          	addi	a0,a0,2030 # 80008760 <syscalls+0x330>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5b6080e7          	jalr	1462(ra) # 80000530 <panic>
    panic("free_desc 2");
    80005f82:	00002517          	auipc	a0,0x2
    80005f86:	7ee50513          	addi	a0,a0,2030 # 80008770 <syscalls+0x340>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5a6080e7          	jalr	1446(ra) # 80000530 <panic>

0000000080005f92 <virtio_disk_init>:
{
    80005f92:	1101                	addi	sp,sp,-32
    80005f94:	ec06                	sd	ra,24(sp)
    80005f96:	e822                	sd	s0,16(sp)
    80005f98:	e426                	sd	s1,8(sp)
    80005f9a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f9c:	00002597          	auipc	a1,0x2
    80005fa0:	7e458593          	addi	a1,a1,2020 # 80008780 <syscalls+0x350>
    80005fa4:	0001f517          	auipc	a0,0x1f
    80005fa8:	18450513          	addi	a0,a0,388 # 80025128 <disk+0x2128>
    80005fac:	ffffb097          	auipc	ra,0xffffb
    80005fb0:	b9a080e7          	jalr	-1126(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fb4:	100017b7          	lui	a5,0x10001
    80005fb8:	4398                	lw	a4,0(a5)
    80005fba:	2701                	sext.w	a4,a4
    80005fbc:	747277b7          	lui	a5,0x74727
    80005fc0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fc4:	0ef71163          	bne	a4,a5,800060a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fc8:	100017b7          	lui	a5,0x10001
    80005fcc:	43dc                	lw	a5,4(a5)
    80005fce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fd0:	4705                	li	a4,1
    80005fd2:	0ce79a63          	bne	a5,a4,800060a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fd6:	100017b7          	lui	a5,0x10001
    80005fda:	479c                	lw	a5,8(a5)
    80005fdc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fde:	4709                	li	a4,2
    80005fe0:	0ce79363          	bne	a5,a4,800060a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fe4:	100017b7          	lui	a5,0x10001
    80005fe8:	47d8                	lw	a4,12(a5)
    80005fea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fec:	554d47b7          	lui	a5,0x554d4
    80005ff0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ff4:	0af71963          	bne	a4,a5,800060a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff8:	100017b7          	lui	a5,0x10001
    80005ffc:	4705                	li	a4,1
    80005ffe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006000:	470d                	li	a4,3
    80006002:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006004:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006006:	c7ffe737          	lui	a4,0xc7ffe
    8000600a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000600e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006010:	2701                	sext.w	a4,a4
    80006012:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006014:	472d                	li	a4,11
    80006016:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006018:	473d                	li	a4,15
    8000601a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000601c:	6705                	lui	a4,0x1
    8000601e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006020:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006024:	5bdc                	lw	a5,52(a5)
    80006026:	2781                	sext.w	a5,a5
  if(max == 0)
    80006028:	c7d9                	beqz	a5,800060b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000602a:	471d                	li	a4,7
    8000602c:	08f77d63          	bgeu	a4,a5,800060c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006030:	100014b7          	lui	s1,0x10001
    80006034:	47a1                	li	a5,8
    80006036:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006038:	6609                	lui	a2,0x2
    8000603a:	4581                	li	a1,0
    8000603c:	0001d517          	auipc	a0,0x1d
    80006040:	fc450513          	addi	a0,a0,-60 # 80023000 <disk>
    80006044:	ffffb097          	auipc	ra,0xffffb
    80006048:	c8e080e7          	jalr	-882(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000604c:	0001d717          	auipc	a4,0x1d
    80006050:	fb470713          	addi	a4,a4,-76 # 80023000 <disk>
    80006054:	00c75793          	srli	a5,a4,0xc
    80006058:	2781                	sext.w	a5,a5
    8000605a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000605c:	0001f797          	auipc	a5,0x1f
    80006060:	fa478793          	addi	a5,a5,-92 # 80025000 <disk+0x2000>
    80006064:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006066:	0001d717          	auipc	a4,0x1d
    8000606a:	01a70713          	addi	a4,a4,26 # 80023080 <disk+0x80>
    8000606e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006070:	0001e717          	auipc	a4,0x1e
    80006074:	f9070713          	addi	a4,a4,-112 # 80024000 <disk+0x1000>
    80006078:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000607a:	4705                	li	a4,1
    8000607c:	00e78c23          	sb	a4,24(a5)
    80006080:	00e78ca3          	sb	a4,25(a5)
    80006084:	00e78d23          	sb	a4,26(a5)
    80006088:	00e78da3          	sb	a4,27(a5)
    8000608c:	00e78e23          	sb	a4,28(a5)
    80006090:	00e78ea3          	sb	a4,29(a5)
    80006094:	00e78f23          	sb	a4,30(a5)
    80006098:	00e78fa3          	sb	a4,31(a5)
}
    8000609c:	60e2                	ld	ra,24(sp)
    8000609e:	6442                	ld	s0,16(sp)
    800060a0:	64a2                	ld	s1,8(sp)
    800060a2:	6105                	addi	sp,sp,32
    800060a4:	8082                	ret
    panic("could not find virtio disk");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	6ea50513          	addi	a0,a0,1770 # 80008790 <syscalls+0x360>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	482080e7          	jalr	1154(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	6fa50513          	addi	a0,a0,1786 # 800087b0 <syscalls+0x380>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	472080e7          	jalr	1138(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    800060c6:	00002517          	auipc	a0,0x2
    800060ca:	70a50513          	addi	a0,a0,1802 # 800087d0 <syscalls+0x3a0>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	462080e7          	jalr	1122(ra) # 80000530 <panic>

00000000800060d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060d6:	7159                	addi	sp,sp,-112
    800060d8:	f486                	sd	ra,104(sp)
    800060da:	f0a2                	sd	s0,96(sp)
    800060dc:	eca6                	sd	s1,88(sp)
    800060de:	e8ca                	sd	s2,80(sp)
    800060e0:	e4ce                	sd	s3,72(sp)
    800060e2:	e0d2                	sd	s4,64(sp)
    800060e4:	fc56                	sd	s5,56(sp)
    800060e6:	f85a                	sd	s6,48(sp)
    800060e8:	f45e                	sd	s7,40(sp)
    800060ea:	f062                	sd	s8,32(sp)
    800060ec:	ec66                	sd	s9,24(sp)
    800060ee:	e86a                	sd	s10,16(sp)
    800060f0:	1880                	addi	s0,sp,112
    800060f2:	892a                	mv	s2,a0
    800060f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060f6:	00c52c83          	lw	s9,12(a0)
    800060fa:	001c9c9b          	slliw	s9,s9,0x1
    800060fe:	1c82                	slli	s9,s9,0x20
    80006100:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006104:	0001f517          	auipc	a0,0x1f
    80006108:	02450513          	addi	a0,a0,36 # 80025128 <disk+0x2128>
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	aca080e7          	jalr	-1334(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006114:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006116:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006118:	0001db97          	auipc	s7,0x1d
    8000611c:	ee8b8b93          	addi	s7,s7,-280 # 80023000 <disk>
    80006120:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006122:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006124:	8a4e                	mv	s4,s3
    80006126:	a051                	j	800061aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006128:	00fb86b3          	add	a3,s7,a5
    8000612c:	96da                	add	a3,a3,s6
    8000612e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006132:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006134:	0207c563          	bltz	a5,8000615e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006138:	2485                	addiw	s1,s1,1
    8000613a:	0711                	addi	a4,a4,4
    8000613c:	25548063          	beq	s1,s5,8000637c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006140:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006142:	0001f697          	auipc	a3,0x1f
    80006146:	ed668693          	addi	a3,a3,-298 # 80025018 <disk+0x2018>
    8000614a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000614c:	0006c583          	lbu	a1,0(a3)
    80006150:	fde1                	bnez	a1,80006128 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006152:	2785                	addiw	a5,a5,1
    80006154:	0685                	addi	a3,a3,1
    80006156:	ff879be3          	bne	a5,s8,8000614c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000615a:	57fd                	li	a5,-1
    8000615c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000615e:	02905a63          	blez	s1,80006192 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006162:	f9042503          	lw	a0,-112(s0)
    80006166:	00000097          	auipc	ra,0x0
    8000616a:	d90080e7          	jalr	-624(ra) # 80005ef6 <free_desc>
      for(int j = 0; j < i; j++)
    8000616e:	4785                	li	a5,1
    80006170:	0297d163          	bge	a5,s1,80006192 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006174:	f9442503          	lw	a0,-108(s0)
    80006178:	00000097          	auipc	ra,0x0
    8000617c:	d7e080e7          	jalr	-642(ra) # 80005ef6 <free_desc>
      for(int j = 0; j < i; j++)
    80006180:	4789                	li	a5,2
    80006182:	0097d863          	bge	a5,s1,80006192 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006186:	f9842503          	lw	a0,-104(s0)
    8000618a:	00000097          	auipc	ra,0x0
    8000618e:	d6c080e7          	jalr	-660(ra) # 80005ef6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006192:	0001f597          	auipc	a1,0x1f
    80006196:	f9658593          	addi	a1,a1,-106 # 80025128 <disk+0x2128>
    8000619a:	0001f517          	auipc	a0,0x1f
    8000619e:	e7e50513          	addi	a0,a0,-386 # 80025018 <disk+0x2018>
    800061a2:	ffffc097          	auipc	ra,0xffffc
    800061a6:	ec4080e7          	jalr	-316(ra) # 80002066 <sleep>
  for(int i = 0; i < 3; i++){
    800061aa:	f9040713          	addi	a4,s0,-112
    800061ae:	84ce                	mv	s1,s3
    800061b0:	bf41                	j	80006140 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061b2:	20058713          	addi	a4,a1,512
    800061b6:	00471693          	slli	a3,a4,0x4
    800061ba:	0001d717          	auipc	a4,0x1d
    800061be:	e4670713          	addi	a4,a4,-442 # 80023000 <disk>
    800061c2:	9736                	add	a4,a4,a3
    800061c4:	4685                	li	a3,1
    800061c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061ca:	20058713          	addi	a4,a1,512
    800061ce:	00471693          	slli	a3,a4,0x4
    800061d2:	0001d717          	auipc	a4,0x1d
    800061d6:	e2e70713          	addi	a4,a4,-466 # 80023000 <disk>
    800061da:	9736                	add	a4,a4,a3
    800061dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061e4:	7679                	lui	a2,0xffffe
    800061e6:	963e                	add	a2,a2,a5
    800061e8:	0001f697          	auipc	a3,0x1f
    800061ec:	e1868693          	addi	a3,a3,-488 # 80025000 <disk+0x2000>
    800061f0:	6298                	ld	a4,0(a3)
    800061f2:	9732                	add	a4,a4,a2
    800061f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061f6:	6298                	ld	a4,0(a3)
    800061f8:	9732                	add	a4,a4,a2
    800061fa:	4541                	li	a0,16
    800061fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061fe:	6298                	ld	a4,0(a3)
    80006200:	9732                	add	a4,a4,a2
    80006202:	4505                	li	a0,1
    80006204:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006208:	f9442703          	lw	a4,-108(s0)
    8000620c:	6288                	ld	a0,0(a3)
    8000620e:	962a                	add	a2,a2,a0
    80006210:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006214:	0712                	slli	a4,a4,0x4
    80006216:	6290                	ld	a2,0(a3)
    80006218:	963a                	add	a2,a2,a4
    8000621a:	05890513          	addi	a0,s2,88
    8000621e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006220:	6294                	ld	a3,0(a3)
    80006222:	96ba                	add	a3,a3,a4
    80006224:	40000613          	li	a2,1024
    80006228:	c690                	sw	a2,8(a3)
  if(write)
    8000622a:	140d0063          	beqz	s10,8000636a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000622e:	0001f697          	auipc	a3,0x1f
    80006232:	dd26b683          	ld	a3,-558(a3) # 80025000 <disk+0x2000>
    80006236:	96ba                	add	a3,a3,a4
    80006238:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000623c:	0001d817          	auipc	a6,0x1d
    80006240:	dc480813          	addi	a6,a6,-572 # 80023000 <disk>
    80006244:	0001f517          	auipc	a0,0x1f
    80006248:	dbc50513          	addi	a0,a0,-580 # 80025000 <disk+0x2000>
    8000624c:	6114                	ld	a3,0(a0)
    8000624e:	96ba                	add	a3,a3,a4
    80006250:	00c6d603          	lhu	a2,12(a3)
    80006254:	00166613          	ori	a2,a2,1
    80006258:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000625c:	f9842683          	lw	a3,-104(s0)
    80006260:	6110                	ld	a2,0(a0)
    80006262:	9732                	add	a4,a4,a2
    80006264:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006268:	20058613          	addi	a2,a1,512
    8000626c:	0612                	slli	a2,a2,0x4
    8000626e:	9642                	add	a2,a2,a6
    80006270:	577d                	li	a4,-1
    80006272:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006276:	00469713          	slli	a4,a3,0x4
    8000627a:	6114                	ld	a3,0(a0)
    8000627c:	96ba                	add	a3,a3,a4
    8000627e:	03078793          	addi	a5,a5,48
    80006282:	97c2                	add	a5,a5,a6
    80006284:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006286:	611c                	ld	a5,0(a0)
    80006288:	97ba                	add	a5,a5,a4
    8000628a:	4685                	li	a3,1
    8000628c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000628e:	611c                	ld	a5,0(a0)
    80006290:	97ba                	add	a5,a5,a4
    80006292:	4809                	li	a6,2
    80006294:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006298:	611c                	ld	a5,0(a0)
    8000629a:	973e                	add	a4,a4,a5
    8000629c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800062a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062a8:	6518                	ld	a4,8(a0)
    800062aa:	00275783          	lhu	a5,2(a4)
    800062ae:	8b9d                	andi	a5,a5,7
    800062b0:	0786                	slli	a5,a5,0x1
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062bc:	6518                	ld	a4,8(a0)
    800062be:	00275783          	lhu	a5,2(a4)
    800062c2:	2785                	addiw	a5,a5,1
    800062c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062cc:	100017b7          	lui	a5,0x10001
    800062d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062d4:	00492703          	lw	a4,4(s2)
    800062d8:	4785                	li	a5,1
    800062da:	02f71163          	bne	a4,a5,800062fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062de:	0001f997          	auipc	s3,0x1f
    800062e2:	e4a98993          	addi	s3,s3,-438 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062e8:	85ce                	mv	a1,s3
    800062ea:	854a                	mv	a0,s2
    800062ec:	ffffc097          	auipc	ra,0xffffc
    800062f0:	d7a080e7          	jalr	-646(ra) # 80002066 <sleep>
  while(b->disk == 1) {
    800062f4:	00492783          	lw	a5,4(s2)
    800062f8:	fe9788e3          	beq	a5,s1,800062e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062fc:	f9042903          	lw	s2,-112(s0)
    80006300:	20090793          	addi	a5,s2,512
    80006304:	00479713          	slli	a4,a5,0x4
    80006308:	0001d797          	auipc	a5,0x1d
    8000630c:	cf878793          	addi	a5,a5,-776 # 80023000 <disk>
    80006310:	97ba                	add	a5,a5,a4
    80006312:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006316:	0001f997          	auipc	s3,0x1f
    8000631a:	cea98993          	addi	s3,s3,-790 # 80025000 <disk+0x2000>
    8000631e:	00491713          	slli	a4,s2,0x4
    80006322:	0009b783          	ld	a5,0(s3)
    80006326:	97ba                	add	a5,a5,a4
    80006328:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000632c:	854a                	mv	a0,s2
    8000632e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006332:	00000097          	auipc	ra,0x0
    80006336:	bc4080e7          	jalr	-1084(ra) # 80005ef6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000633a:	8885                	andi	s1,s1,1
    8000633c:	f0ed                	bnez	s1,8000631e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000633e:	0001f517          	auipc	a0,0x1f
    80006342:	dea50513          	addi	a0,a0,-534 # 80025128 <disk+0x2128>
    80006346:	ffffb097          	auipc	ra,0xffffb
    8000634a:	944080e7          	jalr	-1724(ra) # 80000c8a <release>
}
    8000634e:	70a6                	ld	ra,104(sp)
    80006350:	7406                	ld	s0,96(sp)
    80006352:	64e6                	ld	s1,88(sp)
    80006354:	6946                	ld	s2,80(sp)
    80006356:	69a6                	ld	s3,72(sp)
    80006358:	6a06                	ld	s4,64(sp)
    8000635a:	7ae2                	ld	s5,56(sp)
    8000635c:	7b42                	ld	s6,48(sp)
    8000635e:	7ba2                	ld	s7,40(sp)
    80006360:	7c02                	ld	s8,32(sp)
    80006362:	6ce2                	ld	s9,24(sp)
    80006364:	6d42                	ld	s10,16(sp)
    80006366:	6165                	addi	sp,sp,112
    80006368:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000636a:	0001f697          	auipc	a3,0x1f
    8000636e:	c966b683          	ld	a3,-874(a3) # 80025000 <disk+0x2000>
    80006372:	96ba                	add	a3,a3,a4
    80006374:	4609                	li	a2,2
    80006376:	00c69623          	sh	a2,12(a3)
    8000637a:	b5c9                	j	8000623c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000637c:	f9042583          	lw	a1,-112(s0)
    80006380:	20058793          	addi	a5,a1,512
    80006384:	0792                	slli	a5,a5,0x4
    80006386:	0001d517          	auipc	a0,0x1d
    8000638a:	d2250513          	addi	a0,a0,-734 # 800230a8 <disk+0xa8>
    8000638e:	953e                	add	a0,a0,a5
  if(write)
    80006390:	e20d11e3          	bnez	s10,800061b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006394:	20058713          	addi	a4,a1,512
    80006398:	00471693          	slli	a3,a4,0x4
    8000639c:	0001d717          	auipc	a4,0x1d
    800063a0:	c6470713          	addi	a4,a4,-924 # 80023000 <disk>
    800063a4:	9736                	add	a4,a4,a3
    800063a6:	0a072423          	sw	zero,168(a4)
    800063aa:	b505                	j	800061ca <virtio_disk_rw+0xf4>

00000000800063ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063ac:	1101                	addi	sp,sp,-32
    800063ae:	ec06                	sd	ra,24(sp)
    800063b0:	e822                	sd	s0,16(sp)
    800063b2:	e426                	sd	s1,8(sp)
    800063b4:	e04a                	sd	s2,0(sp)
    800063b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063b8:	0001f517          	auipc	a0,0x1f
    800063bc:	d7050513          	addi	a0,a0,-656 # 80025128 <disk+0x2128>
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	816080e7          	jalr	-2026(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063c8:	10001737          	lui	a4,0x10001
    800063cc:	533c                	lw	a5,96(a4)
    800063ce:	8b8d                	andi	a5,a5,3
    800063d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063d6:	0001f797          	auipc	a5,0x1f
    800063da:	c2a78793          	addi	a5,a5,-982 # 80025000 <disk+0x2000>
    800063de:	6b94                	ld	a3,16(a5)
    800063e0:	0207d703          	lhu	a4,32(a5)
    800063e4:	0026d783          	lhu	a5,2(a3)
    800063e8:	06f70163          	beq	a4,a5,8000644a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ec:	0001d917          	auipc	s2,0x1d
    800063f0:	c1490913          	addi	s2,s2,-1004 # 80023000 <disk>
    800063f4:	0001f497          	auipc	s1,0x1f
    800063f8:	c0c48493          	addi	s1,s1,-1012 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006400:	6898                	ld	a4,16(s1)
    80006402:	0204d783          	lhu	a5,32(s1)
    80006406:	8b9d                	andi	a5,a5,7
    80006408:	078e                	slli	a5,a5,0x3
    8000640a:	97ba                	add	a5,a5,a4
    8000640c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000640e:	20078713          	addi	a4,a5,512
    80006412:	0712                	slli	a4,a4,0x4
    80006414:	974a                	add	a4,a4,s2
    80006416:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000641a:	e731                	bnez	a4,80006466 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000641c:	20078793          	addi	a5,a5,512
    80006420:	0792                	slli	a5,a5,0x4
    80006422:	97ca                	add	a5,a5,s2
    80006424:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006426:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000642a:	ffffc097          	auipc	ra,0xffffc
    8000642e:	dc8080e7          	jalr	-568(ra) # 800021f2 <wakeup>

    disk.used_idx += 1;
    80006432:	0204d783          	lhu	a5,32(s1)
    80006436:	2785                	addiw	a5,a5,1
    80006438:	17c2                	slli	a5,a5,0x30
    8000643a:	93c1                	srli	a5,a5,0x30
    8000643c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006440:	6898                	ld	a4,16(s1)
    80006442:	00275703          	lhu	a4,2(a4)
    80006446:	faf71be3          	bne	a4,a5,800063fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000644a:	0001f517          	auipc	a0,0x1f
    8000644e:	cde50513          	addi	a0,a0,-802 # 80025128 <disk+0x2128>
    80006452:	ffffb097          	auipc	ra,0xffffb
    80006456:	838080e7          	jalr	-1992(ra) # 80000c8a <release>
}
    8000645a:	60e2                	ld	ra,24(sp)
    8000645c:	6442                	ld	s0,16(sp)
    8000645e:	64a2                	ld	s1,8(sp)
    80006460:	6902                	ld	s2,0(sp)
    80006462:	6105                	addi	sp,sp,32
    80006464:	8082                	ret
      panic("virtio_disk_intr status");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	38a50513          	addi	a0,a0,906 # 800087f0 <syscalls+0x3c0>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0c2080e7          	jalr	194(ra) # 80000530 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
