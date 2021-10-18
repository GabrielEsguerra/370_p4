
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
    80000068:	b3c78793          	addi	a5,a5,-1220 # 80005ba0 <timervec>
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
    80000122:	334080e7          	jalr	820(ra) # 80002452 <either_copyin>
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
    800001ca:	e92080e7          	jalr	-366(ra) # 80002058 <sleep>
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
    80000206:	1fa080e7          	jalr	506(ra) # 800023fc <either_copyout>
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
    800002e8:	1c4080e7          	jalr	452(ra) # 800024a8 <procdump>
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
    8000043c:	dac080e7          	jalr	-596(ra) # 800021e4 <wakeup>
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
    8000046e:	eae78793          	addi	a5,a5,-338 # 80021318 <devsw>
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
    80000896:	952080e7          	jalr	-1710(ra) # 800021e4 <wakeup>
    
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
    80000922:	73a080e7          	jalr	1850(ra) # 80002058 <sleep>
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
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	772080e7          	jalr	1906(ra) # 8000263c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	d0e080e7          	jalr	-754(ra) # 80005be0 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	fcc080e7          	jalr	-52(ra) # 80001ea6 <scheduler>
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
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	6d2080e7          	jalr	1746(ra) # 80002614 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	6f2080e7          	jalr	1778(ra) # 8000263c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	c78080e7          	jalr	-904(ra) # 80005bca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	c86080e7          	jalr	-890(ra) # 80005be0 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	e66080e7          	jalr	-410(ra) # 80002dc8 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	4f6080e7          	jalr	1270(ra) # 80003460 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	4a0080e7          	jalr	1184(ra) # 80004412 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	d88080e7          	jalr	-632(ra) # 80005d02 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	cea080e7          	jalr	-790(ra) # 80001c6c <userinit>
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
    80001856:	87ea0a13          	addi	s4,s4,-1922 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	28c080e7          	jalr	652(ra) # 80000ae6 <kalloc>
    80001862:	862a                	mv	a2,a0
    if(pa == 0)
    80001864:	c131                	beqz	a0,800018a8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001866:	416485b3          	sub	a1,s1,s6
    8000186a:	858d                	srai	a1,a1,0x3
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
    8000188c:	16848493          	addi	s1,s1,360
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
    8000191e:	00015997          	auipc	s3,0x15
    80001922:	7b298993          	addi	s3,s3,1970 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001926:	85da                	mv	a1,s6
    80001928:	8526                	mv	a0,s1
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	21c080e7          	jalr	540(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001932:	415487b3          	sub	a5,s1,s5
    80001936:	878d                	srai	a5,a5,0x3
    80001938:	000a3703          	ld	a4,0(s4)
    8000193c:	02e787b3          	mul	a5,a5,a4
    80001940:	2785                	addiw	a5,a5,1
    80001942:	00d7979b          	slliw	a5,a5,0xd
    80001946:	40f907b3          	sub	a5,s2,a5
    8000194a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	16848493          	addi	s1,s1,360
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
    800019e8:	e2c7a783          	lw	a5,-468(a5) # 80008810 <first.1679>
    800019ec:	eb89                	bnez	a5,800019fe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ee:	00001097          	auipc	ra,0x1
    800019f2:	c66080e7          	jalr	-922(ra) # 80002654 <usertrapret>
}
    800019f6:	60a2                	ld	ra,8(sp)
    800019f8:	6402                	ld	s0,0(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret
    first = 0;
    800019fe:	00007797          	auipc	a5,0x7
    80001a02:	e007a923          	sw	zero,-494(a5) # 80008810 <first.1679>
    fsinit(ROOTDEV);
    80001a06:	4505                	li	a0,1
    80001a08:	00002097          	auipc	ra,0x2
    80001a0c:	9d8080e7          	jalr	-1576(ra) # 800033e0 <fsinit>
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
    80001b9e:	1101                	addi	sp,sp,-32
    80001ba0:	ec06                	sd	ra,24(sp)
    80001ba2:	e822                	sd	s0,16(sp)
    80001ba4:	e426                	sd	s1,8(sp)
    80001ba6:	e04a                	sd	s2,0(sp)
    80001ba8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001baa:	00010497          	auipc	s1,0x10
    80001bae:	b2648493          	addi	s1,s1,-1242 # 800116d0 <proc>
    80001bb2:	00015917          	auipc	s2,0x15
    80001bb6:	51e90913          	addi	s2,s2,1310 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	01a080e7          	jalr	26(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bc4:	4c9c                	lw	a5,24(s1)
    80001bc6:	cf81                	beqz	a5,80001bde <allocproc+0x40>
      release(&p->lock);
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	0c0080e7          	jalr	192(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	16848493          	addi	s1,s1,360
    80001bd6:	ff2492e3          	bne	s1,s2,80001bba <allocproc+0x1c>
  return 0;
    80001bda:	4481                	li	s1,0
    80001bdc:	a889                	j	80001c2e <allocproc+0x90>
  p->pid = allocpid();
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	e34080e7          	jalr	-460(ra) # 80001a12 <allocpid>
    80001be6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001be8:	4785                	li	a5,1
    80001bea:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	efa080e7          	jalr	-262(ra) # 80000ae6 <kalloc>
    80001bf4:	892a                	mv	s2,a0
    80001bf6:	eca8                	sd	a0,88(s1)
    80001bf8:	c131                	beqz	a0,80001c3c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	e5c080e7          	jalr	-420(ra) # 80001a58 <proc_pagetable>
    80001c04:	892a                	mv	s2,a0
    80001c06:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c08:	c531                	beqz	a0,80001c54 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0a:	07000613          	li	a2,112
    80001c0e:	4581                	li	a1,0
    80001c10:	06048513          	addi	a0,s1,96
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0be080e7          	jalr	190(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c1c:	00000797          	auipc	a5,0x0
    80001c20:	db078793          	addi	a5,a5,-592 # 800019cc <forkret>
    80001c24:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c26:	60bc                	ld	a5,64(s1)
    80001c28:	6705                	lui	a4,0x1
    80001c2a:	97ba                	add	a5,a5,a4
    80001c2c:	f4bc                	sd	a5,104(s1)
}
    80001c2e:	8526                	mv	a0,s1
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret
    freeproc(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	f08080e7          	jalr	-248(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	042080e7          	jalr	66(ra) # 80000c8a <release>
    return 0;
    80001c50:	84ca                	mv	s1,s2
    80001c52:	bff1                	j	80001c2e <allocproc+0x90>
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	ef0080e7          	jalr	-272(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	b7d1                	j	80001c2e <allocproc+0x90>

0000000080001c6c <userinit>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f28080e7          	jalr	-216(ra) # 80001b9e <allocproc>
    80001c7e:	84aa                	mv	s1,a0
  initproc = p;
    80001c80:	00007797          	auipc	a5,0x7
    80001c84:	3aa7b423          	sd	a0,936(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c88:	03400613          	li	a2,52
    80001c8c:	00007597          	auipc	a1,0x7
    80001c90:	b9458593          	addi	a1,a1,-1132 # 80008820 <initcode>
    80001c94:	6928                	ld	a0,80(a0)
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	6b6080e7          	jalr	1718(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001c9e:	6785                	lui	a5,0x1
    80001ca0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca2:	6cb8                	ld	a4,88(s1)
    80001ca4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ca8:	6cb8                	ld	a4,88(s1)
    80001caa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cac:	4641                	li	a2,16
    80001cae:	00006597          	auipc	a1,0x6
    80001cb2:	53a58593          	addi	a1,a1,1338 # 800081e8 <digits+0x1a8>
    80001cb6:	15848513          	addi	a0,s1,344
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	16e080e7          	jalr	366(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001cc2:	00006517          	auipc	a0,0x6
    80001cc6:	53650513          	addi	a0,a0,1334 # 800081f8 <digits+0x1b8>
    80001cca:	00002097          	auipc	ra,0x2
    80001cce:	144080e7          	jalr	324(ra) # 80003e0e <namei>
    80001cd2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd6:	478d                	li	a5,3
    80001cd8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	fae080e7          	jalr	-82(ra) # 80000c8a <release>
}
    80001ce4:	60e2                	ld	ra,24(sp)
    80001ce6:	6442                	ld	s0,16(sp)
    80001ce8:	64a2                	ld	s1,8(sp)
    80001cea:	6105                	addi	sp,sp,32
    80001cec:	8082                	ret

0000000080001cee <growproc>:
{
    80001cee:	1101                	addi	sp,sp,-32
    80001cf0:	ec06                	sd	ra,24(sp)
    80001cf2:	e822                	sd	s0,16(sp)
    80001cf4:	e426                	sd	s1,8(sp)
    80001cf6:	e04a                	sd	s2,0(sp)
    80001cf8:	1000                	addi	s0,sp,32
    80001cfa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	c98080e7          	jalr	-872(ra) # 80001994 <myproc>
    80001d04:	892a                	mv	s2,a0
  sz = p->sz;
    80001d06:	652c                	ld	a1,72(a0)
    80001d08:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d0c:	00904f63          	bgtz	s1,80001d2a <growproc+0x3c>
  } else if(n < 0){
    80001d10:	0204cc63          	bltz	s1,80001d48 <growproc+0x5a>
  p->sz = sz;
    80001d14:	1602                	slli	a2,a2,0x20
    80001d16:	9201                	srli	a2,a2,0x20
    80001d18:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d1c:	4501                	li	a0,0
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6902                	ld	s2,0(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2a:	9e25                	addw	a2,a2,s1
    80001d2c:	1602                	slli	a2,a2,0x20
    80001d2e:	9201                	srli	a2,a2,0x20
    80001d30:	1582                	slli	a1,a1,0x20
    80001d32:	9181                	srli	a1,a1,0x20
    80001d34:	6928                	ld	a0,80(a0)
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	6d0080e7          	jalr	1744(ra) # 80001406 <uvmalloc>
    80001d3e:	0005061b          	sext.w	a2,a0
    80001d42:	fa69                	bnez	a2,80001d14 <growproc+0x26>
      return -1;
    80001d44:	557d                	li	a0,-1
    80001d46:	bfe1                	j	80001d1e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d48:	9e25                	addw	a2,a2,s1
    80001d4a:	1602                	slli	a2,a2,0x20
    80001d4c:	9201                	srli	a2,a2,0x20
    80001d4e:	1582                	slli	a1,a1,0x20
    80001d50:	9181                	srli	a1,a1,0x20
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	66a080e7          	jalr	1642(ra) # 800013be <uvmdealloc>
    80001d5c:	0005061b          	sext.w	a2,a0
    80001d60:	bf55                	j	80001d14 <growproc+0x26>

0000000080001d62 <fork>:
{
    80001d62:	7179                	addi	sp,sp,-48
    80001d64:	f406                	sd	ra,40(sp)
    80001d66:	f022                	sd	s0,32(sp)
    80001d68:	ec26                	sd	s1,24(sp)
    80001d6a:	e84a                	sd	s2,16(sp)
    80001d6c:	e44e                	sd	s3,8(sp)
    80001d6e:	e052                	sd	s4,0(sp)
    80001d70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	c22080e7          	jalr	-990(ra) # 80001994 <myproc>
    80001d7a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	e22080e7          	jalr	-478(ra) # 80001b9e <allocproc>
    80001d84:	10050f63          	beqz	a0,80001ea2 <fork+0x140>
    80001d88:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8a:	04893603          	ld	a2,72(s2)
    80001d8e:	692c                	ld	a1,80(a0)
    80001d90:	05093503          	ld	a0,80(s2)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	7be080e7          	jalr	1982(ra) # 80001552 <uvmcopy>
    80001d9c:	04054a63          	bltz	a0,80001df0 <fork+0x8e>
  np->sz = p->sz;
    80001da0:	04893783          	ld	a5,72(s2)
    80001da4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001da8:	05893683          	ld	a3,88(s2)
    80001dac:	87b6                	mv	a5,a3
    80001dae:	0589b703          	ld	a4,88(s3)
    80001db2:	12068693          	addi	a3,a3,288
    80001db6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dba:	6788                	ld	a0,8(a5)
    80001dbc:	6b8c                	ld	a1,16(a5)
    80001dbe:	6f90                	ld	a2,24(a5)
    80001dc0:	01073023          	sd	a6,0(a4)
    80001dc4:	e708                	sd	a0,8(a4)
    80001dc6:	eb0c                	sd	a1,16(a4)
    80001dc8:	ef10                	sd	a2,24(a4)
    80001dca:	02078793          	addi	a5,a5,32
    80001dce:	02070713          	addi	a4,a4,32
    80001dd2:	fed792e3          	bne	a5,a3,80001db6 <fork+0x54>
  np->mask = p->mask; // copy trace mask from parent to child
    80001dd6:	03492783          	lw	a5,52(s2)
    80001dda:	02f9aa23          	sw	a5,52(s3)
  np->trapframe->a0 = 0;
    80001dde:	0589b783          	ld	a5,88(s3)
    80001de2:	0607b823          	sd	zero,112(a5)
    80001de6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dea:	15000a13          	li	s4,336
    80001dee:	a03d                	j	80001e1c <fork+0xba>
    freeproc(np);
    80001df0:	854e                	mv	a0,s3
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	d54080e7          	jalr	-684(ra) # 80001b46 <freeproc>
    release(&np->lock);
    80001dfa:	854e                	mv	a0,s3
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	e8e080e7          	jalr	-370(ra) # 80000c8a <release>
    return -1;
    80001e04:	5a7d                	li	s4,-1
    80001e06:	a069                	j	80001e90 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e08:	00002097          	auipc	ra,0x2
    80001e0c:	69c080e7          	jalr	1692(ra) # 800044a4 <filedup>
    80001e10:	009987b3          	add	a5,s3,s1
    80001e14:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e16:	04a1                	addi	s1,s1,8
    80001e18:	01448763          	beq	s1,s4,80001e26 <fork+0xc4>
    if(p->ofile[i])
    80001e1c:	009907b3          	add	a5,s2,s1
    80001e20:	6388                	ld	a0,0(a5)
    80001e22:	f17d                	bnez	a0,80001e08 <fork+0xa6>
    80001e24:	bfcd                	j	80001e16 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e26:	15093503          	ld	a0,336(s2)
    80001e2a:	00001097          	auipc	ra,0x1
    80001e2e:	7f0080e7          	jalr	2032(ra) # 8000361a <idup>
    80001e32:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	15890593          	addi	a1,s2,344
    80001e3c:	15898513          	addi	a0,s3,344
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	fe8080e7          	jalr	-24(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e48:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e4c:	854e                	mv	a0,s3
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e3c080e7          	jalr	-452(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e56:	0000f497          	auipc	s1,0xf
    80001e5a:	46248493          	addi	s1,s1,1122 # 800112b8 <wait_lock>
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	d76080e7          	jalr	-650(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e68:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e1c080e7          	jalr	-484(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e76:	854e                	mv	a0,s3
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d5e080e7          	jalr	-674(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e80:	478d                	li	a5,3
    80001e82:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e86:	854e                	mv	a0,s3
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
}
    80001e90:	8552                	mv	a0,s4
    80001e92:	70a2                	ld	ra,40(sp)
    80001e94:	7402                	ld	s0,32(sp)
    80001e96:	64e2                	ld	s1,24(sp)
    80001e98:	6942                	ld	s2,16(sp)
    80001e9a:	69a2                	ld	s3,8(sp)
    80001e9c:	6a02                	ld	s4,0(sp)
    80001e9e:	6145                	addi	sp,sp,48
    80001ea0:	8082                	ret
    return -1;
    80001ea2:	5a7d                	li	s4,-1
    80001ea4:	b7f5                	j	80001e90 <fork+0x12e>

0000000080001ea6 <scheduler>:
{
    80001ea6:	7139                	addi	sp,sp,-64
    80001ea8:	fc06                	sd	ra,56(sp)
    80001eaa:	f822                	sd	s0,48(sp)
    80001eac:	f426                	sd	s1,40(sp)
    80001eae:	f04a                	sd	s2,32(sp)
    80001eb0:	ec4e                	sd	s3,24(sp)
    80001eb2:	e852                	sd	s4,16(sp)
    80001eb4:	e456                	sd	s5,8(sp)
    80001eb6:	e05a                	sd	s6,0(sp)
    80001eb8:	0080                	addi	s0,sp,64
    80001eba:	8792                	mv	a5,tp
  int id = r_tp();
    80001ebc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ebe:	00779a93          	slli	s5,a5,0x7
    80001ec2:	0000f717          	auipc	a4,0xf
    80001ec6:	3de70713          	addi	a4,a4,990 # 800112a0 <pid_lock>
    80001eca:	9756                	add	a4,a4,s5
    80001ecc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed0:	0000f717          	auipc	a4,0xf
    80001ed4:	40870713          	addi	a4,a4,1032 # 800112d8 <cpus+0x8>
    80001ed8:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eda:	498d                	li	s3,3
        p->state = RUNNING;
    80001edc:	4b11                	li	s6,4
        c->proc = p;
    80001ede:	079e                	slli	a5,a5,0x7
    80001ee0:	0000fa17          	auipc	s4,0xf
    80001ee4:	3c0a0a13          	addi	s4,s4,960 # 800112a0 <pid_lock>
    80001ee8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eea:	00015917          	auipc	s2,0x15
    80001eee:	1e690913          	addi	s2,s2,486 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001efa:	10079073          	csrw	sstatus,a5
    80001efe:	0000f497          	auipc	s1,0xf
    80001f02:	7d248493          	addi	s1,s1,2002 # 800116d0 <proc>
    80001f06:	a03d                	j	80001f34 <scheduler+0x8e>
        p->state = RUNNING;
    80001f08:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f0c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f10:	06048593          	addi	a1,s1,96
    80001f14:	8556                	mv	a0,s5
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	694080e7          	jalr	1684(ra) # 800025aa <swtch>
        c->proc = 0;
    80001f1e:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	d66080e7          	jalr	-666(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f2c:	16848493          	addi	s1,s1,360
    80001f30:	fd2481e3          	beq	s1,s2,80001ef2 <scheduler+0x4c>
      acquire(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	ca0080e7          	jalr	-864(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f3e:	4c9c                	lw	a5,24(s1)
    80001f40:	ff3791e3          	bne	a5,s3,80001f22 <scheduler+0x7c>
    80001f44:	b7d1                	j	80001f08 <scheduler+0x62>

0000000080001f46 <sched>:
{
    80001f46:	7179                	addi	sp,sp,-48
    80001f48:	f406                	sd	ra,40(sp)
    80001f4a:	f022                	sd	s0,32(sp)
    80001f4c:	ec26                	sd	s1,24(sp)
    80001f4e:	e84a                	sd	s2,16(sp)
    80001f50:	e44e                	sd	s3,8(sp)
    80001f52:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f54:	00000097          	auipc	ra,0x0
    80001f58:	a40080e7          	jalr	-1472(ra) # 80001994 <myproc>
    80001f5c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	bfe080e7          	jalr	-1026(ra) # 80000b5c <holding>
    80001f66:	c93d                	beqz	a0,80001fdc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f68:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f6a:	2781                	sext.w	a5,a5
    80001f6c:	079e                	slli	a5,a5,0x7
    80001f6e:	0000f717          	auipc	a4,0xf
    80001f72:	33270713          	addi	a4,a4,818 # 800112a0 <pid_lock>
    80001f76:	97ba                	add	a5,a5,a4
    80001f78:	0a87a703          	lw	a4,168(a5)
    80001f7c:	4785                	li	a5,1
    80001f7e:	06f71763          	bne	a4,a5,80001fec <sched+0xa6>
  if(p->state == RUNNING)
    80001f82:	4c98                	lw	a4,24(s1)
    80001f84:	4791                	li	a5,4
    80001f86:	06f70b63          	beq	a4,a5,80001ffc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f90:	efb5                	bnez	a5,8000200c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f92:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f94:	0000f917          	auipc	s2,0xf
    80001f98:	30c90913          	addi	s2,s2,780 # 800112a0 <pid_lock>
    80001f9c:	2781                	sext.w	a5,a5
    80001f9e:	079e                	slli	a5,a5,0x7
    80001fa0:	97ca                	add	a5,a5,s2
    80001fa2:	0ac7a983          	lw	s3,172(a5)
    80001fa6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa8:	2781                	sext.w	a5,a5
    80001faa:	079e                	slli	a5,a5,0x7
    80001fac:	0000f597          	auipc	a1,0xf
    80001fb0:	32c58593          	addi	a1,a1,812 # 800112d8 <cpus+0x8>
    80001fb4:	95be                	add	a1,a1,a5
    80001fb6:	06048513          	addi	a0,s1,96
    80001fba:	00000097          	auipc	ra,0x0
    80001fbe:	5f0080e7          	jalr	1520(ra) # 800025aa <swtch>
    80001fc2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc4:	2781                	sext.w	a5,a5
    80001fc6:	079e                	slli	a5,a5,0x7
    80001fc8:	97ca                	add	a5,a5,s2
    80001fca:	0b37a623          	sw	s3,172(a5)
}
    80001fce:	70a2                	ld	ra,40(sp)
    80001fd0:	7402                	ld	s0,32(sp)
    80001fd2:	64e2                	ld	s1,24(sp)
    80001fd4:	6942                	ld	s2,16(sp)
    80001fd6:	69a2                	ld	s3,8(sp)
    80001fd8:	6145                	addi	sp,sp,48
    80001fda:	8082                	ret
    panic("sched p->lock");
    80001fdc:	00006517          	auipc	a0,0x6
    80001fe0:	22450513          	addi	a0,a0,548 # 80008200 <digits+0x1c0>
    80001fe4:	ffffe097          	auipc	ra,0xffffe
    80001fe8:	54c080e7          	jalr	1356(ra) # 80000530 <panic>
    panic("sched locks");
    80001fec:	00006517          	auipc	a0,0x6
    80001ff0:	22450513          	addi	a0,a0,548 # 80008210 <digits+0x1d0>
    80001ff4:	ffffe097          	auipc	ra,0xffffe
    80001ff8:	53c080e7          	jalr	1340(ra) # 80000530 <panic>
    panic("sched running");
    80001ffc:	00006517          	auipc	a0,0x6
    80002000:	22450513          	addi	a0,a0,548 # 80008220 <digits+0x1e0>
    80002004:	ffffe097          	auipc	ra,0xffffe
    80002008:	52c080e7          	jalr	1324(ra) # 80000530 <panic>
    panic("sched interruptible");
    8000200c:	00006517          	auipc	a0,0x6
    80002010:	22450513          	addi	a0,a0,548 # 80008230 <digits+0x1f0>
    80002014:	ffffe097          	auipc	ra,0xffffe
    80002018:	51c080e7          	jalr	1308(ra) # 80000530 <panic>

000000008000201c <yield>:
{
    8000201c:	1101                	addi	sp,sp,-32
    8000201e:	ec06                	sd	ra,24(sp)
    80002020:	e822                	sd	s0,16(sp)
    80002022:	e426                	sd	s1,8(sp)
    80002024:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	96e080e7          	jalr	-1682(ra) # 80001994 <myproc>
    8000202e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	ba6080e7          	jalr	-1114(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002038:	478d                	li	a5,3
    8000203a:	cc9c                	sw	a5,24(s1)
  sched();
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	f0a080e7          	jalr	-246(ra) # 80001f46 <sched>
  release(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c44080e7          	jalr	-956(ra) # 80000c8a <release>
}
    8000204e:	60e2                	ld	ra,24(sp)
    80002050:	6442                	ld	s0,16(sp)
    80002052:	64a2                	ld	s1,8(sp)
    80002054:	6105                	addi	sp,sp,32
    80002056:	8082                	ret

0000000080002058 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002058:	7179                	addi	sp,sp,-48
    8000205a:	f406                	sd	ra,40(sp)
    8000205c:	f022                	sd	s0,32(sp)
    8000205e:	ec26                	sd	s1,24(sp)
    80002060:	e84a                	sd	s2,16(sp)
    80002062:	e44e                	sd	s3,8(sp)
    80002064:	1800                	addi	s0,sp,48
    80002066:	89aa                	mv	s3,a0
    80002068:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	92a080e7          	jalr	-1750(ra) # 80001994 <myproc>
    80002072:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	b62080e7          	jalr	-1182(ra) # 80000bd6 <acquire>
  release(lk);
    8000207c:	854a                	mv	a0,s2
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c0c080e7          	jalr	-1012(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002086:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000208a:	4789                	li	a5,2
    8000208c:	cc9c                	sw	a5,24(s1)

  sched();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	eb8080e7          	jalr	-328(ra) # 80001f46 <sched>

  // Tidy up.
  p->chan = 0;
    80002096:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bee080e7          	jalr	-1042(ra) # 80000c8a <release>
  acquire(lk);
    800020a4:	854a                	mv	a0,s2
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	b30080e7          	jalr	-1232(ra) # 80000bd6 <acquire>
}
    800020ae:	70a2                	ld	ra,40(sp)
    800020b0:	7402                	ld	s0,32(sp)
    800020b2:	64e2                	ld	s1,24(sp)
    800020b4:	6942                	ld	s2,16(sp)
    800020b6:	69a2                	ld	s3,8(sp)
    800020b8:	6145                	addi	sp,sp,48
    800020ba:	8082                	ret

00000000800020bc <wait>:
{
    800020bc:	715d                	addi	sp,sp,-80
    800020be:	e486                	sd	ra,72(sp)
    800020c0:	e0a2                	sd	s0,64(sp)
    800020c2:	fc26                	sd	s1,56(sp)
    800020c4:	f84a                	sd	s2,48(sp)
    800020c6:	f44e                	sd	s3,40(sp)
    800020c8:	f052                	sd	s4,32(sp)
    800020ca:	ec56                	sd	s5,24(sp)
    800020cc:	e85a                	sd	s6,16(sp)
    800020ce:	e45e                	sd	s7,8(sp)
    800020d0:	e062                	sd	s8,0(sp)
    800020d2:	0880                	addi	s0,sp,80
    800020d4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	8be080e7          	jalr	-1858(ra) # 80001994 <myproc>
    800020de:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020e0:	0000f517          	auipc	a0,0xf
    800020e4:	1d850513          	addi	a0,a0,472 # 800112b8 <wait_lock>
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	aee080e7          	jalr	-1298(ra) # 80000bd6 <acquire>
    havekids = 0;
    800020f0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f2:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800020f4:	00015997          	auipc	s3,0x15
    800020f8:	fdc98993          	addi	s3,s3,-36 # 800170d0 <tickslock>
        havekids = 1;
    800020fc:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020fe:	0000fc17          	auipc	s8,0xf
    80002102:	1bac0c13          	addi	s8,s8,442 # 800112b8 <wait_lock>
    havekids = 0;
    80002106:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002108:	0000f497          	auipc	s1,0xf
    8000210c:	5c848493          	addi	s1,s1,1480 # 800116d0 <proc>
    80002110:	a0bd                	j	8000217e <wait+0xc2>
          pid = np->pid;
    80002112:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002116:	000b0e63          	beqz	s6,80002132 <wait+0x76>
    8000211a:	4691                	li	a3,4
    8000211c:	02c48613          	addi	a2,s1,44
    80002120:	85da                	mv	a1,s6
    80002122:	05093503          	ld	a0,80(s2)
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	530080e7          	jalr	1328(ra) # 80001656 <copyout>
    8000212e:	02054563          	bltz	a0,80002158 <wait+0x9c>
          freeproc(np);
    80002132:	8526                	mv	a0,s1
    80002134:	00000097          	auipc	ra,0x0
    80002138:	a12080e7          	jalr	-1518(ra) # 80001b46 <freeproc>
          release(&np->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b4c080e7          	jalr	-1204(ra) # 80000c8a <release>
          release(&wait_lock);
    80002146:	0000f517          	auipc	a0,0xf
    8000214a:	17250513          	addi	a0,a0,370 # 800112b8 <wait_lock>
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	b3c080e7          	jalr	-1220(ra) # 80000c8a <release>
          return pid;
    80002156:	a09d                	j	800021bc <wait+0x100>
            release(&np->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b30080e7          	jalr	-1232(ra) # 80000c8a <release>
            release(&wait_lock);
    80002162:	0000f517          	auipc	a0,0xf
    80002166:	15650513          	addi	a0,a0,342 # 800112b8 <wait_lock>
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b20080e7          	jalr	-1248(ra) # 80000c8a <release>
            return -1;
    80002172:	59fd                	li	s3,-1
    80002174:	a0a1                	j	800021bc <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002176:	16848493          	addi	s1,s1,360
    8000217a:	03348463          	beq	s1,s3,800021a2 <wait+0xe6>
      if(np->parent == p){
    8000217e:	7c9c                	ld	a5,56(s1)
    80002180:	ff279be3          	bne	a5,s2,80002176 <wait+0xba>
        acquire(&np->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    8000218e:	4c9c                	lw	a5,24(s1)
    80002190:	f94781e3          	beq	a5,s4,80002112 <wait+0x56>
        release(&np->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	af4080e7          	jalr	-1292(ra) # 80000c8a <release>
        havekids = 1;
    8000219e:	8756                	mv	a4,s5
    800021a0:	bfd9                	j	80002176 <wait+0xba>
    if(!havekids || p->killed){
    800021a2:	c701                	beqz	a4,800021aa <wait+0xee>
    800021a4:	02892783          	lw	a5,40(s2)
    800021a8:	c79d                	beqz	a5,800021d6 <wait+0x11a>
      release(&wait_lock);
    800021aa:	0000f517          	auipc	a0,0xf
    800021ae:	10e50513          	addi	a0,a0,270 # 800112b8 <wait_lock>
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ad8080e7          	jalr	-1320(ra) # 80000c8a <release>
      return -1;
    800021ba:	59fd                	li	s3,-1
}
    800021bc:	854e                	mv	a0,s3
    800021be:	60a6                	ld	ra,72(sp)
    800021c0:	6406                	ld	s0,64(sp)
    800021c2:	74e2                	ld	s1,56(sp)
    800021c4:	7942                	ld	s2,48(sp)
    800021c6:	79a2                	ld	s3,40(sp)
    800021c8:	7a02                	ld	s4,32(sp)
    800021ca:	6ae2                	ld	s5,24(sp)
    800021cc:	6b42                	ld	s6,16(sp)
    800021ce:	6ba2                	ld	s7,8(sp)
    800021d0:	6c02                	ld	s8,0(sp)
    800021d2:	6161                	addi	sp,sp,80
    800021d4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d6:	85e2                	mv	a1,s8
    800021d8:	854a                	mv	a0,s2
    800021da:	00000097          	auipc	ra,0x0
    800021de:	e7e080e7          	jalr	-386(ra) # 80002058 <sleep>
    havekids = 0;
    800021e2:	b715                	j	80002106 <wait+0x4a>

00000000800021e4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e4:	7139                	addi	sp,sp,-64
    800021e6:	fc06                	sd	ra,56(sp)
    800021e8:	f822                	sd	s0,48(sp)
    800021ea:	f426                	sd	s1,40(sp)
    800021ec:	f04a                	sd	s2,32(sp)
    800021ee:	ec4e                	sd	s3,24(sp)
    800021f0:	e852                	sd	s4,16(sp)
    800021f2:	e456                	sd	s5,8(sp)
    800021f4:	0080                	addi	s0,sp,64
    800021f6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f8:	0000f497          	auipc	s1,0xf
    800021fc:	4d848493          	addi	s1,s1,1240 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002200:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002202:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002204:	00015917          	auipc	s2,0x15
    80002208:	ecc90913          	addi	s2,s2,-308 # 800170d0 <tickslock>
    8000220c:	a821                	j	80002224 <wakeup+0x40>
        p->state = RUNNABLE;
    8000220e:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a76080e7          	jalr	-1418(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000221c:	16848493          	addi	s1,s1,360
    80002220:	03248463          	beq	s1,s2,80002248 <wakeup+0x64>
    if(p != myproc()){
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	770080e7          	jalr	1904(ra) # 80001994 <myproc>
    8000222c:	fea488e3          	beq	s1,a0,8000221c <wakeup+0x38>
      acquire(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9a4080e7          	jalr	-1628(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000223a:	4c9c                	lw	a5,24(s1)
    8000223c:	fd379be3          	bne	a5,s3,80002212 <wakeup+0x2e>
    80002240:	709c                	ld	a5,32(s1)
    80002242:	fd4798e3          	bne	a5,s4,80002212 <wakeup+0x2e>
    80002246:	b7e1                	j	8000220e <wakeup+0x2a>
    }
  }
}
    80002248:	70e2                	ld	ra,56(sp)
    8000224a:	7442                	ld	s0,48(sp)
    8000224c:	74a2                	ld	s1,40(sp)
    8000224e:	7902                	ld	s2,32(sp)
    80002250:	69e2                	ld	s3,24(sp)
    80002252:	6a42                	ld	s4,16(sp)
    80002254:	6aa2                	ld	s5,8(sp)
    80002256:	6121                	addi	sp,sp,64
    80002258:	8082                	ret

000000008000225a <reparent>:
{
    8000225a:	7179                	addi	sp,sp,-48
    8000225c:	f406                	sd	ra,40(sp)
    8000225e:	f022                	sd	s0,32(sp)
    80002260:	ec26                	sd	s1,24(sp)
    80002262:	e84a                	sd	s2,16(sp)
    80002264:	e44e                	sd	s3,8(sp)
    80002266:	e052                	sd	s4,0(sp)
    80002268:	1800                	addi	s0,sp,48
    8000226a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226c:	0000f497          	auipc	s1,0xf
    80002270:	46448493          	addi	s1,s1,1124 # 800116d0 <proc>
      pp->parent = initproc;
    80002274:	00007a17          	auipc	s4,0x7
    80002278:	db4a0a13          	addi	s4,s4,-588 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227c:	00015997          	auipc	s3,0x15
    80002280:	e5498993          	addi	s3,s3,-428 # 800170d0 <tickslock>
    80002284:	a029                	j	8000228e <reparent+0x34>
    80002286:	16848493          	addi	s1,s1,360
    8000228a:	01348d63          	beq	s1,s3,800022a4 <reparent+0x4a>
    if(pp->parent == p){
    8000228e:	7c9c                	ld	a5,56(s1)
    80002290:	ff279be3          	bne	a5,s2,80002286 <reparent+0x2c>
      pp->parent = initproc;
    80002294:	000a3503          	ld	a0,0(s4)
    80002298:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	f4a080e7          	jalr	-182(ra) # 800021e4 <wakeup>
    800022a2:	b7d5                	j	80002286 <reparent+0x2c>
}
    800022a4:	70a2                	ld	ra,40(sp)
    800022a6:	7402                	ld	s0,32(sp)
    800022a8:	64e2                	ld	s1,24(sp)
    800022aa:	6942                	ld	s2,16(sp)
    800022ac:	69a2                	ld	s3,8(sp)
    800022ae:	6a02                	ld	s4,0(sp)
    800022b0:	6145                	addi	sp,sp,48
    800022b2:	8082                	ret

00000000800022b4 <exit>:
{
    800022b4:	7179                	addi	sp,sp,-48
    800022b6:	f406                	sd	ra,40(sp)
    800022b8:	f022                	sd	s0,32(sp)
    800022ba:	ec26                	sd	s1,24(sp)
    800022bc:	e84a                	sd	s2,16(sp)
    800022be:	e44e                	sd	s3,8(sp)
    800022c0:	e052                	sd	s4,0(sp)
    800022c2:	1800                	addi	s0,sp,48
    800022c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	6ce080e7          	jalr	1742(ra) # 80001994 <myproc>
    800022ce:	89aa                	mv	s3,a0
  if(p == initproc)
    800022d0:	00007797          	auipc	a5,0x7
    800022d4:	d587b783          	ld	a5,-680(a5) # 80009028 <initproc>
    800022d8:	0d050493          	addi	s1,a0,208
    800022dc:	15050913          	addi	s2,a0,336
    800022e0:	02a79363          	bne	a5,a0,80002306 <exit+0x52>
    panic("init exiting");
    800022e4:	00006517          	auipc	a0,0x6
    800022e8:	f6450513          	addi	a0,a0,-156 # 80008248 <digits+0x208>
    800022ec:	ffffe097          	auipc	ra,0xffffe
    800022f0:	244080e7          	jalr	580(ra) # 80000530 <panic>
      fileclose(f);
    800022f4:	00002097          	auipc	ra,0x2
    800022f8:	202080e7          	jalr	514(ra) # 800044f6 <fileclose>
      p->ofile[fd] = 0;
    800022fc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002300:	04a1                	addi	s1,s1,8
    80002302:	01248563          	beq	s1,s2,8000230c <exit+0x58>
    if(p->ofile[fd]){
    80002306:	6088                	ld	a0,0(s1)
    80002308:	f575                	bnez	a0,800022f4 <exit+0x40>
    8000230a:	bfdd                	j	80002300 <exit+0x4c>
  begin_op();
    8000230c:	00002097          	auipc	ra,0x2
    80002310:	d1e080e7          	jalr	-738(ra) # 8000402a <begin_op>
  iput(p->cwd);
    80002314:	1509b503          	ld	a0,336(s3)
    80002318:	00001097          	auipc	ra,0x1
    8000231c:	4fa080e7          	jalr	1274(ra) # 80003812 <iput>
  end_op();
    80002320:	00002097          	auipc	ra,0x2
    80002324:	d8a080e7          	jalr	-630(ra) # 800040aa <end_op>
  p->cwd = 0;
    80002328:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232c:	0000f497          	auipc	s1,0xf
    80002330:	f8c48493          	addi	s1,s1,-116 # 800112b8 <wait_lock>
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	8a0080e7          	jalr	-1888(ra) # 80000bd6 <acquire>
  reparent(p);
    8000233e:	854e                	mv	a0,s3
    80002340:	00000097          	auipc	ra,0x0
    80002344:	f1a080e7          	jalr	-230(ra) # 8000225a <reparent>
  wakeup(p->parent);
    80002348:	0389b503          	ld	a0,56(s3)
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	e98080e7          	jalr	-360(ra) # 800021e4 <wakeup>
  acquire(&p->lock);
    80002354:	854e                	mv	a0,s3
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000235e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002362:	4795                	li	a5,5
    80002364:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	920080e7          	jalr	-1760(ra) # 80000c8a <release>
  sched();
    80002372:	00000097          	auipc	ra,0x0
    80002376:	bd4080e7          	jalr	-1068(ra) # 80001f46 <sched>
  panic("zombie exit");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ede50513          	addi	a0,a0,-290 # 80008258 <digits+0x218>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1ae080e7          	jalr	430(ra) # 80000530 <panic>

000000008000238a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000238a:	7179                	addi	sp,sp,-48
    8000238c:	f406                	sd	ra,40(sp)
    8000238e:	f022                	sd	s0,32(sp)
    80002390:	ec26                	sd	s1,24(sp)
    80002392:	e84a                	sd	s2,16(sp)
    80002394:	e44e                	sd	s3,8(sp)
    80002396:	1800                	addi	s0,sp,48
    80002398:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	33648493          	addi	s1,s1,822 # 800116d0 <proc>
    800023a2:	00015997          	auipc	s3,0x15
    800023a6:	d2e98993          	addi	s3,s3,-722 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	82a080e7          	jalr	-2006(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800023b4:	589c                	lw	a5,48(s1)
    800023b6:	01278d63          	beq	a5,s2,800023d0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8ce080e7          	jalr	-1842(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c4:	16848493          	addi	s1,s1,360
    800023c8:	ff3491e3          	bne	s1,s3,800023aa <kill+0x20>
  }
  return -1;
    800023cc:	557d                	li	a0,-1
    800023ce:	a829                	j	800023e8 <kill+0x5e>
      p->killed = 1;
    800023d0:	4785                	li	a5,1
    800023d2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d4:	4c98                	lw	a4,24(s1)
    800023d6:	4789                	li	a5,2
    800023d8:	00f70f63          	beq	a4,a5,800023f6 <kill+0x6c>
      release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ac080e7          	jalr	-1876(ra) # 80000c8a <release>
      return 0;
    800023e6:	4501                	li	a0,0
}
    800023e8:	70a2                	ld	ra,40(sp)
    800023ea:	7402                	ld	s0,32(sp)
    800023ec:	64e2                	ld	s1,24(sp)
    800023ee:	6942                	ld	s2,16(sp)
    800023f0:	69a2                	ld	s3,8(sp)
    800023f2:	6145                	addi	sp,sp,48
    800023f4:	8082                	ret
        p->state = RUNNABLE;
    800023f6:	478d                	li	a5,3
    800023f8:	cc9c                	sw	a5,24(s1)
    800023fa:	b7cd                	j	800023dc <kill+0x52>

00000000800023fc <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	e052                	sd	s4,0(sp)
    8000240a:	1800                	addi	s0,sp,48
    8000240c:	84aa                	mv	s1,a0
    8000240e:	892e                	mv	s2,a1
    80002410:	89b2                	mv	s3,a2
    80002412:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	580080e7          	jalr	1408(ra) # 80001994 <myproc>
  if(user_dst){
    8000241c:	c08d                	beqz	s1,8000243e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000241e:	86d2                	mv	a3,s4
    80002420:	864e                	mv	a2,s3
    80002422:	85ca                	mv	a1,s2
    80002424:	6928                	ld	a0,80(a0)
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	230080e7          	jalr	560(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000242e:	70a2                	ld	ra,40(sp)
    80002430:	7402                	ld	s0,32(sp)
    80002432:	64e2                	ld	s1,24(sp)
    80002434:	6942                	ld	s2,16(sp)
    80002436:	69a2                	ld	s3,8(sp)
    80002438:	6a02                	ld	s4,0(sp)
    8000243a:	6145                	addi	sp,sp,48
    8000243c:	8082                	ret
    memmove((char *)dst, src, len);
    8000243e:	000a061b          	sext.w	a2,s4
    80002442:	85ce                	mv	a1,s3
    80002444:	854a                	mv	a0,s2
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	8ec080e7          	jalr	-1812(ra) # 80000d32 <memmove>
    return 0;
    8000244e:	8526                	mv	a0,s1
    80002450:	bff9                	j	8000242e <either_copyout+0x32>

0000000080002452 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	e052                	sd	s4,0(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	892a                	mv	s2,a0
    80002464:	84ae                	mv	s1,a1
    80002466:	89b2                	mv	s3,a2
    80002468:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	52a080e7          	jalr	1322(ra) # 80001994 <myproc>
  if(user_src){
    80002472:	c08d                	beqz	s1,80002494 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002474:	86d2                	mv	a3,s4
    80002476:	864e                	mv	a2,s3
    80002478:	85ca                	mv	a1,s2
    8000247a:	6928                	ld	a0,80(a0)
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	266080e7          	jalr	614(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6a02                	ld	s4,0(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret
    memmove(dst, (char*)src, len);
    80002494:	000a061b          	sext.w	a2,s4
    80002498:	85ce                	mv	a1,s3
    8000249a:	854a                	mv	a0,s2
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	896080e7          	jalr	-1898(ra) # 80000d32 <memmove>
    return 0;
    800024a4:	8526                	mv	a0,s1
    800024a6:	bff9                	j	80002484 <either_copyin+0x32>

00000000800024a8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024a8:	715d                	addi	sp,sp,-80
    800024aa:	e486                	sd	ra,72(sp)
    800024ac:	e0a2                	sd	s0,64(sp)
    800024ae:	fc26                	sd	s1,56(sp)
    800024b0:	f84a                	sd	s2,48(sp)
    800024b2:	f44e                	sd	s3,40(sp)
    800024b4:	f052                	sd	s4,32(sp)
    800024b6:	ec56                	sd	s5,24(sp)
    800024b8:	e85a                	sd	s6,16(sp)
    800024ba:	e45e                	sd	s7,8(sp)
    800024bc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024be:	00006517          	auipc	a0,0x6
    800024c2:	c0a50513          	addi	a0,a0,-1014 # 800080c8 <digits+0x88>
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	0b4080e7          	jalr	180(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ce:	0000f497          	auipc	s1,0xf
    800024d2:	35a48493          	addi	s1,s1,858 # 80011828 <proc+0x158>
    800024d6:	00015917          	auipc	s2,0x15
    800024da:	d5290913          	addi	s2,s2,-686 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024de:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024e0:	00006997          	auipc	s3,0x6
    800024e4:	d8898993          	addi	s3,s3,-632 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024e8:	00006a97          	auipc	s5,0x6
    800024ec:	d88a8a93          	addi	s5,s5,-632 # 80008270 <digits+0x230>
    printf("\n");
    800024f0:	00006a17          	auipc	s4,0x6
    800024f4:	bd8a0a13          	addi	s4,s4,-1064 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f8:	00006b97          	auipc	s7,0x6
    800024fc:	db0b8b93          	addi	s7,s7,-592 # 800082a8 <states.1716>
    80002500:	a00d                	j	80002522 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002502:	ed86a583          	lw	a1,-296(a3)
    80002506:	8556                	mv	a0,s5
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	072080e7          	jalr	114(ra) # 8000057a <printf>
    printf("\n");
    80002510:	8552                	mv	a0,s4
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	068080e7          	jalr	104(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251a:	16848493          	addi	s1,s1,360
    8000251e:	03248163          	beq	s1,s2,80002540 <procdump+0x98>
    if(p->state == UNUSED)
    80002522:	86a6                	mv	a3,s1
    80002524:	ec04a783          	lw	a5,-320(s1)
    80002528:	dbed                	beqz	a5,8000251a <procdump+0x72>
      state = "???";
    8000252a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252c:	fcfb6be3          	bltu	s6,a5,80002502 <procdump+0x5a>
    80002530:	1782                	slli	a5,a5,0x20
    80002532:	9381                	srli	a5,a5,0x20
    80002534:	078e                	slli	a5,a5,0x3
    80002536:	97de                	add	a5,a5,s7
    80002538:	6390                	ld	a2,0(a5)
    8000253a:	f661                	bnez	a2,80002502 <procdump+0x5a>
      state = "???";
    8000253c:	864e                	mv	a2,s3
    8000253e:	b7d1                	j	80002502 <procdump+0x5a>
  }
}
    80002540:	60a6                	ld	ra,72(sp)
    80002542:	6406                	ld	s0,64(sp)
    80002544:	74e2                	ld	s1,56(sp)
    80002546:	7942                	ld	s2,48(sp)
    80002548:	79a2                	ld	s3,40(sp)
    8000254a:	7a02                	ld	s4,32(sp)
    8000254c:	6ae2                	ld	s5,24(sp)
    8000254e:	6b42                	ld	s6,16(sp)
    80002550:	6ba2                	ld	s7,8(sp)
    80002552:	6161                	addi	sp,sp,80
    80002554:	8082                	ret

0000000080002556 <nproc>:

uint64
nproc(void) {
    80002556:	7179                	addi	sp,sp,-48
    80002558:	f406                	sd	ra,40(sp)
    8000255a:	f022                	sd	s0,32(sp)
    8000255c:	ec26                	sd	s1,24(sp)
    8000255e:	e84a                	sd	s2,16(sp)
    80002560:	e44e                	sd	s3,8(sp)
    80002562:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 n = 0;
    80002564:	4901                	li	s2,0

  for(p = proc; p < &proc[NPROC]; p++) {
    80002566:	0000f497          	auipc	s1,0xf
    8000256a:	16a48493          	addi	s1,s1,362 # 800116d0 <proc>
    8000256e:	00015997          	auipc	s3,0x15
    80002572:	b6298993          	addi	s3,s3,-1182 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	65e080e7          	jalr	1630(ra) # 80000bd6 <acquire>
    if(p->state != UNUSED) 
    80002580:	4c9c                	lw	a5,24(s1)
    n++;
    80002582:	00f037b3          	snez	a5,a5
    80002586:	993e                	add	s2,s2,a5
    release(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	700080e7          	jalr	1792(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002592:	16848493          	addi	s1,s1,360
    80002596:	ff3490e3          	bne	s1,s3,80002576 <nproc+0x20>
  }

  return n;
    8000259a:	854a                	mv	a0,s2
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6145                	addi	sp,sp,48
    800025a8:	8082                	ret

00000000800025aa <swtch>:
    800025aa:	00153023          	sd	ra,0(a0)
    800025ae:	00253423          	sd	sp,8(a0)
    800025b2:	e900                	sd	s0,16(a0)
    800025b4:	ed04                	sd	s1,24(a0)
    800025b6:	03253023          	sd	s2,32(a0)
    800025ba:	03353423          	sd	s3,40(a0)
    800025be:	03453823          	sd	s4,48(a0)
    800025c2:	03553c23          	sd	s5,56(a0)
    800025c6:	05653023          	sd	s6,64(a0)
    800025ca:	05753423          	sd	s7,72(a0)
    800025ce:	05853823          	sd	s8,80(a0)
    800025d2:	05953c23          	sd	s9,88(a0)
    800025d6:	07a53023          	sd	s10,96(a0)
    800025da:	07b53423          	sd	s11,104(a0)
    800025de:	0005b083          	ld	ra,0(a1)
    800025e2:	0085b103          	ld	sp,8(a1)
    800025e6:	6980                	ld	s0,16(a1)
    800025e8:	6d84                	ld	s1,24(a1)
    800025ea:	0205b903          	ld	s2,32(a1)
    800025ee:	0285b983          	ld	s3,40(a1)
    800025f2:	0305ba03          	ld	s4,48(a1)
    800025f6:	0385ba83          	ld	s5,56(a1)
    800025fa:	0405bb03          	ld	s6,64(a1)
    800025fe:	0485bb83          	ld	s7,72(a1)
    80002602:	0505bc03          	ld	s8,80(a1)
    80002606:	0585bc83          	ld	s9,88(a1)
    8000260a:	0605bd03          	ld	s10,96(a1)
    8000260e:	0685bd83          	ld	s11,104(a1)
    80002612:	8082                	ret

0000000080002614 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002614:	1141                	addi	sp,sp,-16
    80002616:	e406                	sd	ra,8(sp)
    80002618:	e022                	sd	s0,0(sp)
    8000261a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000261c:	00006597          	auipc	a1,0x6
    80002620:	cbc58593          	addi	a1,a1,-836 # 800082d8 <states.1716+0x30>
    80002624:	00015517          	auipc	a0,0x15
    80002628:	aac50513          	addi	a0,a0,-1364 # 800170d0 <tickslock>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	51a080e7          	jalr	1306(ra) # 80000b46 <initlock>
}
    80002634:	60a2                	ld	ra,8(sp)
    80002636:	6402                	ld	s0,0(sp)
    80002638:	0141                	addi	sp,sp,16
    8000263a:	8082                	ret

000000008000263c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000263c:	1141                	addi	sp,sp,-16
    8000263e:	e422                	sd	s0,8(sp)
    80002640:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002642:	00003797          	auipc	a5,0x3
    80002646:	4ce78793          	addi	a5,a5,1230 # 80005b10 <kernelvec>
    8000264a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000264e:	6422                	ld	s0,8(sp)
    80002650:	0141                	addi	sp,sp,16
    80002652:	8082                	ret

0000000080002654 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002654:	1141                	addi	sp,sp,-16
    80002656:	e406                	sd	ra,8(sp)
    80002658:	e022                	sd	s0,0(sp)
    8000265a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000265c:	fffff097          	auipc	ra,0xfffff
    80002660:	338080e7          	jalr	824(ra) # 80001994 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002664:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002668:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000266e:	00005617          	auipc	a2,0x5
    80002672:	99260613          	addi	a2,a2,-1646 # 80007000 <_trampoline>
    80002676:	00005697          	auipc	a3,0x5
    8000267a:	98a68693          	addi	a3,a3,-1654 # 80007000 <_trampoline>
    8000267e:	8e91                	sub	a3,a3,a2
    80002680:	040007b7          	lui	a5,0x4000
    80002684:	17fd                	addi	a5,a5,-1
    80002686:	07b2                	slli	a5,a5,0xc
    80002688:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000268e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002690:	180026f3          	csrr	a3,satp
    80002694:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002696:	6d38                	ld	a4,88(a0)
    80002698:	6134                	ld	a3,64(a0)
    8000269a:	6585                	lui	a1,0x1
    8000269c:	96ae                	add	a3,a3,a1
    8000269e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a0:	6d38                	ld	a4,88(a0)
    800026a2:	00000697          	auipc	a3,0x0
    800026a6:	13868693          	addi	a3,a3,312 # 800027da <usertrap>
    800026aa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ac:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ae:	8692                	mv	a3,tp
    800026b0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026b6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026ba:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026be:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026c4:	6f18                	ld	a4,24(a4)
    800026c6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ca:	692c                	ld	a1,80(a0)
    800026cc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026ce:	00005717          	auipc	a4,0x5
    800026d2:	9c270713          	addi	a4,a4,-1598 # 80007090 <userret>
    800026d6:	8f11                	sub	a4,a4,a2
    800026d8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026da:	577d                	li	a4,-1
    800026dc:	177e                	slli	a4,a4,0x3f
    800026de:	8dd9                	or	a1,a1,a4
    800026e0:	02000537          	lui	a0,0x2000
    800026e4:	157d                	addi	a0,a0,-1
    800026e6:	0536                	slli	a0,a0,0xd
    800026e8:	9782                	jalr	a5
}
    800026ea:	60a2                	ld	ra,8(sp)
    800026ec:	6402                	ld	s0,0(sp)
    800026ee:	0141                	addi	sp,sp,16
    800026f0:	8082                	ret

00000000800026f2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f2:	1101                	addi	sp,sp,-32
    800026f4:	ec06                	sd	ra,24(sp)
    800026f6:	e822                	sd	s0,16(sp)
    800026f8:	e426                	sd	s1,8(sp)
    800026fa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026fc:	00015497          	auipc	s1,0x15
    80002700:	9d448493          	addi	s1,s1,-1580 # 800170d0 <tickslock>
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	4d0080e7          	jalr	1232(ra) # 80000bd6 <acquire>
  ticks++;
    8000270e:	00007517          	auipc	a0,0x7
    80002712:	92250513          	addi	a0,a0,-1758 # 80009030 <ticks>
    80002716:	411c                	lw	a5,0(a0)
    80002718:	2785                	addiw	a5,a5,1
    8000271a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000271c:	00000097          	auipc	ra,0x0
    80002720:	ac8080e7          	jalr	-1336(ra) # 800021e4 <wakeup>
  release(&tickslock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	564080e7          	jalr	1380(ra) # 80000c8a <release>
}
    8000272e:	60e2                	ld	ra,24(sp)
    80002730:	6442                	ld	s0,16(sp)
    80002732:	64a2                	ld	s1,8(sp)
    80002734:	6105                	addi	sp,sp,32
    80002736:	8082                	ret

0000000080002738 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002738:	1101                	addi	sp,sp,-32
    8000273a:	ec06                	sd	ra,24(sp)
    8000273c:	e822                	sd	s0,16(sp)
    8000273e:	e426                	sd	s1,8(sp)
    80002740:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002742:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002746:	00074d63          	bltz	a4,80002760 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000274a:	57fd                	li	a5,-1
    8000274c:	17fe                	slli	a5,a5,0x3f
    8000274e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002750:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002752:	06f70363          	beq	a4,a5,800027b8 <devintr+0x80>
  }
}
    80002756:	60e2                	ld	ra,24(sp)
    80002758:	6442                	ld	s0,16(sp)
    8000275a:	64a2                	ld	s1,8(sp)
    8000275c:	6105                	addi	sp,sp,32
    8000275e:	8082                	ret
     (scause & 0xff) == 9){
    80002760:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002764:	46a5                	li	a3,9
    80002766:	fed792e3          	bne	a5,a3,8000274a <devintr+0x12>
    int irq = plic_claim();
    8000276a:	00003097          	auipc	ra,0x3
    8000276e:	4ae080e7          	jalr	1198(ra) # 80005c18 <plic_claim>
    80002772:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002774:	47a9                	li	a5,10
    80002776:	02f50763          	beq	a0,a5,800027a4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000277a:	4785                	li	a5,1
    8000277c:	02f50963          	beq	a0,a5,800027ae <devintr+0x76>
    return 1;
    80002780:	4505                	li	a0,1
    } else if(irq){
    80002782:	d8f1                	beqz	s1,80002756 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002784:	85a6                	mv	a1,s1
    80002786:	00006517          	auipc	a0,0x6
    8000278a:	b5a50513          	addi	a0,a0,-1190 # 800082e0 <states.1716+0x38>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	dec080e7          	jalr	-532(ra) # 8000057a <printf>
      plic_complete(irq);
    80002796:	8526                	mv	a0,s1
    80002798:	00003097          	auipc	ra,0x3
    8000279c:	4a4080e7          	jalr	1188(ra) # 80005c3c <plic_complete>
    return 1;
    800027a0:	4505                	li	a0,1
    800027a2:	bf55                	j	80002756 <devintr+0x1e>
      uartintr();
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	1f6080e7          	jalr	502(ra) # 8000099a <uartintr>
    800027ac:	b7ed                	j	80002796 <devintr+0x5e>
      virtio_disk_intr();
    800027ae:	00004097          	auipc	ra,0x4
    800027b2:	96e080e7          	jalr	-1682(ra) # 8000611c <virtio_disk_intr>
    800027b6:	b7c5                	j	80002796 <devintr+0x5e>
    if(cpuid() == 0){
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	1b0080e7          	jalr	432(ra) # 80001968 <cpuid>
    800027c0:	c901                	beqz	a0,800027d0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027c8:	14479073          	csrw	sip,a5
    return 2;
    800027cc:	4509                	li	a0,2
    800027ce:	b761                	j	80002756 <devintr+0x1e>
      clockintr();
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	f22080e7          	jalr	-222(ra) # 800026f2 <clockintr>
    800027d8:	b7ed                	j	800027c2 <devintr+0x8a>

00000000800027da <usertrap>:
{
    800027da:	1101                	addi	sp,sp,-32
    800027dc:	ec06                	sd	ra,24(sp)
    800027de:	e822                	sd	s0,16(sp)
    800027e0:	e426                	sd	s1,8(sp)
    800027e2:	e04a                	sd	s2,0(sp)
    800027e4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ea:	1007f793          	andi	a5,a5,256
    800027ee:	e3ad                	bnez	a5,80002850 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f0:	00003797          	auipc	a5,0x3
    800027f4:	32078793          	addi	a5,a5,800 # 80005b10 <kernelvec>
    800027f8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	198080e7          	jalr	408(ra) # 80001994 <myproc>
    80002804:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002806:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002808:	14102773          	csrr	a4,sepc
    8000280c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002812:	47a1                	li	a5,8
    80002814:	04f71c63          	bne	a4,a5,8000286c <usertrap+0x92>
    if(p->killed)
    80002818:	551c                	lw	a5,40(a0)
    8000281a:	e3b9                	bnez	a5,80002860 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000281c:	6cb8                	ld	a4,88(s1)
    8000281e:	6f1c                	ld	a5,24(a4)
    80002820:	0791                	addi	a5,a5,4
    80002822:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002824:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002828:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282c:	10079073          	csrw	sstatus,a5
    syscall();
    80002830:	00000097          	auipc	ra,0x0
    80002834:	2e0080e7          	jalr	736(ra) # 80002b10 <syscall>
  if(p->killed)
    80002838:	549c                	lw	a5,40(s1)
    8000283a:	ebc1                	bnez	a5,800028ca <usertrap+0xf0>
  usertrapret();
    8000283c:	00000097          	auipc	ra,0x0
    80002840:	e18080e7          	jalr	-488(ra) # 80002654 <usertrapret>
}
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	64a2                	ld	s1,8(sp)
    8000284a:	6902                	ld	s2,0(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret
    panic("usertrap: not from user mode");
    80002850:	00006517          	auipc	a0,0x6
    80002854:	ab050513          	addi	a0,a0,-1360 # 80008300 <states.1716+0x58>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	cd8080e7          	jalr	-808(ra) # 80000530 <panic>
      exit(-1);
    80002860:	557d                	li	a0,-1
    80002862:	00000097          	auipc	ra,0x0
    80002866:	a52080e7          	jalr	-1454(ra) # 800022b4 <exit>
    8000286a:	bf4d                	j	8000281c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	ecc080e7          	jalr	-308(ra) # 80002738 <devintr>
    80002874:	892a                	mv	s2,a0
    80002876:	c501                	beqz	a0,8000287e <usertrap+0xa4>
  if(p->killed)
    80002878:	549c                	lw	a5,40(s1)
    8000287a:	c3a1                	beqz	a5,800028ba <usertrap+0xe0>
    8000287c:	a815                	j	800028b0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002882:	5890                	lw	a2,48(s1)
    80002884:	00006517          	auipc	a0,0x6
    80002888:	a9c50513          	addi	a0,a0,-1380 # 80008320 <states.1716+0x78>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	cee080e7          	jalr	-786(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002894:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002898:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	ab450513          	addi	a0,a0,-1356 # 80008350 <states.1716+0xa8>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	cd6080e7          	jalr	-810(ra) # 8000057a <printf>
    p->killed = 1;
    800028ac:	4785                	li	a5,1
    800028ae:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028b0:	557d                	li	a0,-1
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	a02080e7          	jalr	-1534(ra) # 800022b4 <exit>
  if(which_dev == 2)
    800028ba:	4789                	li	a5,2
    800028bc:	f8f910e3          	bne	s2,a5,8000283c <usertrap+0x62>
    yield();
    800028c0:	fffff097          	auipc	ra,0xfffff
    800028c4:	75c080e7          	jalr	1884(ra) # 8000201c <yield>
    800028c8:	bf95                	j	8000283c <usertrap+0x62>
  int which_dev = 0;
    800028ca:	4901                	li	s2,0
    800028cc:	b7d5                	j	800028b0 <usertrap+0xd6>

00000000800028ce <kerneltrap>:
{
    800028ce:	7179                	addi	sp,sp,-48
    800028d0:	f406                	sd	ra,40(sp)
    800028d2:	f022                	sd	s0,32(sp)
    800028d4:	ec26                	sd	s1,24(sp)
    800028d6:	e84a                	sd	s2,16(sp)
    800028d8:	e44e                	sd	s3,8(sp)
    800028da:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028dc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028e8:	1004f793          	andi	a5,s1,256
    800028ec:	cb85                	beqz	a5,8000291c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f4:	ef85                	bnez	a5,8000292c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	e42080e7          	jalr	-446(ra) # 80002738 <devintr>
    800028fe:	cd1d                	beqz	a0,8000293c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002900:	4789                	li	a5,2
    80002902:	06f50a63          	beq	a0,a5,80002976 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002906:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290a:	10049073          	csrw	sstatus,s1
}
    8000290e:	70a2                	ld	ra,40(sp)
    80002910:	7402                	ld	s0,32(sp)
    80002912:	64e2                	ld	s1,24(sp)
    80002914:	6942                	ld	s2,16(sp)
    80002916:	69a2                	ld	s3,8(sp)
    80002918:	6145                	addi	sp,sp,48
    8000291a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	a5450513          	addi	a0,a0,-1452 # 80008370 <states.1716+0xc8>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c0c080e7          	jalr	-1012(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	a6c50513          	addi	a0,a0,-1428 # 80008398 <states.1716+0xf0>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	bfc080e7          	jalr	-1028(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    8000293c:	85ce                	mv	a1,s3
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	a7a50513          	addi	a0,a0,-1414 # 800083b8 <states.1716+0x110>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	c34080e7          	jalr	-972(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000294e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002952:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	a7250513          	addi	a0,a0,-1422 # 800083c8 <states.1716+0x120>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	c1c080e7          	jalr	-996(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a7a50513          	addi	a0,a0,-1414 # 800083e0 <states.1716+0x138>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	bc2080e7          	jalr	-1086(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	01e080e7          	jalr	30(ra) # 80001994 <myproc>
    8000297e:	d541                	beqz	a0,80002906 <kerneltrap+0x38>
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	014080e7          	jalr	20(ra) # 80001994 <myproc>
    80002988:	4d18                	lw	a4,24(a0)
    8000298a:	4791                	li	a5,4
    8000298c:	f6f71de3          	bne	a4,a5,80002906 <kerneltrap+0x38>
    yield();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	68c080e7          	jalr	1676(ra) # 8000201c <yield>
    80002998:	b7bd                	j	80002906 <kerneltrap+0x38>

000000008000299a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000299a:	1101                	addi	sp,sp,-32
    8000299c:	ec06                	sd	ra,24(sp)
    8000299e:	e822                	sd	s0,16(sp)
    800029a0:	e426                	sd	s1,8(sp)
    800029a2:	1000                	addi	s0,sp,32
    800029a4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	fee080e7          	jalr	-18(ra) # 80001994 <myproc>
  switch (n) {
    800029ae:	4795                	li	a5,5
    800029b0:	0497e163          	bltu	a5,s1,800029f2 <argraw+0x58>
    800029b4:	048a                	slli	s1,s1,0x2
    800029b6:	00006717          	auipc	a4,0x6
    800029ba:	a6270713          	addi	a4,a4,-1438 # 80008418 <states.1716+0x170>
    800029be:	94ba                	add	s1,s1,a4
    800029c0:	409c                	lw	a5,0(s1)
    800029c2:	97ba                	add	a5,a5,a4
    800029c4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029c6:	6d3c                	ld	a5,88(a0)
    800029c8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ca:	60e2                	ld	ra,24(sp)
    800029cc:	6442                	ld	s0,16(sp)
    800029ce:	64a2                	ld	s1,8(sp)
    800029d0:	6105                	addi	sp,sp,32
    800029d2:	8082                	ret
    return p->trapframe->a1;
    800029d4:	6d3c                	ld	a5,88(a0)
    800029d6:	7fa8                	ld	a0,120(a5)
    800029d8:	bfcd                	j	800029ca <argraw+0x30>
    return p->trapframe->a2;
    800029da:	6d3c                	ld	a5,88(a0)
    800029dc:	63c8                	ld	a0,128(a5)
    800029de:	b7f5                	j	800029ca <argraw+0x30>
    return p->trapframe->a3;
    800029e0:	6d3c                	ld	a5,88(a0)
    800029e2:	67c8                	ld	a0,136(a5)
    800029e4:	b7dd                	j	800029ca <argraw+0x30>
    return p->trapframe->a4;
    800029e6:	6d3c                	ld	a5,88(a0)
    800029e8:	6bc8                	ld	a0,144(a5)
    800029ea:	b7c5                	j	800029ca <argraw+0x30>
    return p->trapframe->a5;
    800029ec:	6d3c                	ld	a5,88(a0)
    800029ee:	6fc8                	ld	a0,152(a5)
    800029f0:	bfe9                	j	800029ca <argraw+0x30>
  panic("argraw");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	9fe50513          	addi	a0,a0,-1538 # 800083f0 <states.1716+0x148>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b36080e7          	jalr	-1226(ra) # 80000530 <panic>

0000000080002a02 <fetchaddr>:
{
    80002a02:	1101                	addi	sp,sp,-32
    80002a04:	ec06                	sd	ra,24(sp)
    80002a06:	e822                	sd	s0,16(sp)
    80002a08:	e426                	sd	s1,8(sp)
    80002a0a:	e04a                	sd	s2,0(sp)
    80002a0c:	1000                	addi	s0,sp,32
    80002a0e:	84aa                	mv	s1,a0
    80002a10:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	f82080e7          	jalr	-126(ra) # 80001994 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a1a:	653c                	ld	a5,72(a0)
    80002a1c:	02f4f863          	bgeu	s1,a5,80002a4c <fetchaddr+0x4a>
    80002a20:	00848713          	addi	a4,s1,8
    80002a24:	02e7e663          	bltu	a5,a4,80002a50 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a28:	46a1                	li	a3,8
    80002a2a:	8626                	mv	a2,s1
    80002a2c:	85ca                	mv	a1,s2
    80002a2e:	6928                	ld	a0,80(a0)
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	cb2080e7          	jalr	-846(ra) # 800016e2 <copyin>
    80002a38:	00a03533          	snez	a0,a0
    80002a3c:	40a00533          	neg	a0,a0
}
    80002a40:	60e2                	ld	ra,24(sp)
    80002a42:	6442                	ld	s0,16(sp)
    80002a44:	64a2                	ld	s1,8(sp)
    80002a46:	6902                	ld	s2,0(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret
    return -1;
    80002a4c:	557d                	li	a0,-1
    80002a4e:	bfcd                	j	80002a40 <fetchaddr+0x3e>
    80002a50:	557d                	li	a0,-1
    80002a52:	b7fd                	j	80002a40 <fetchaddr+0x3e>

0000000080002a54 <fetchstr>:
{
    80002a54:	7179                	addi	sp,sp,-48
    80002a56:	f406                	sd	ra,40(sp)
    80002a58:	f022                	sd	s0,32(sp)
    80002a5a:	ec26                	sd	s1,24(sp)
    80002a5c:	e84a                	sd	s2,16(sp)
    80002a5e:	e44e                	sd	s3,8(sp)
    80002a60:	1800                	addi	s0,sp,48
    80002a62:	892a                	mv	s2,a0
    80002a64:	84ae                	mv	s1,a1
    80002a66:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	f2c080e7          	jalr	-212(ra) # 80001994 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a70:	86ce                	mv	a3,s3
    80002a72:	864a                	mv	a2,s2
    80002a74:	85a6                	mv	a1,s1
    80002a76:	6928                	ld	a0,80(a0)
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	cf6080e7          	jalr	-778(ra) # 8000176e <copyinstr>
  if(err < 0)
    80002a80:	00054763          	bltz	a0,80002a8e <fetchstr+0x3a>
  return strlen(buf);
    80002a84:	8526                	mv	a0,s1
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	3d4080e7          	jalr	980(ra) # 80000e5a <strlen>
}
    80002a8e:	70a2                	ld	ra,40(sp)
    80002a90:	7402                	ld	s0,32(sp)
    80002a92:	64e2                	ld	s1,24(sp)
    80002a94:	6942                	ld	s2,16(sp)
    80002a96:	69a2                	ld	s3,8(sp)
    80002a98:	6145                	addi	sp,sp,48
    80002a9a:	8082                	ret

0000000080002a9c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a9c:	1101                	addi	sp,sp,-32
    80002a9e:	ec06                	sd	ra,24(sp)
    80002aa0:	e822                	sd	s0,16(sp)
    80002aa2:	e426                	sd	s1,8(sp)
    80002aa4:	1000                	addi	s0,sp,32
    80002aa6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	ef2080e7          	jalr	-270(ra) # 8000299a <argraw>
    80002ab0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab2:	4501                	li	a0,0
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6105                	addi	sp,sp,32
    80002abc:	8082                	ret

0000000080002abe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002abe:	1101                	addi	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	1000                	addi	s0,sp,32
    80002ac8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	ed0080e7          	jalr	-304(ra) # 8000299a <argraw>
    80002ad2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ad4:	4501                	li	a0,0
    80002ad6:	60e2                	ld	ra,24(sp)
    80002ad8:	6442                	ld	s0,16(sp)
    80002ada:	64a2                	ld	s1,8(sp)
    80002adc:	6105                	addi	sp,sp,32
    80002ade:	8082                	ret

0000000080002ae0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	e04a                	sd	s2,0(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84ae                	mv	s1,a1
    80002aee:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	eaa080e7          	jalr	-342(ra) # 8000299a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002af8:	864a                	mv	a2,s2
    80002afa:	85a6                	mv	a1,s1
    80002afc:	00000097          	auipc	ra,0x0
    80002b00:	f58080e7          	jalr	-168(ra) # 80002a54 <fetchstr>
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6902                	ld	s2,0(sp)
    80002b0c:	6105                	addi	sp,sp,32
    80002b0e:	8082                	ret

0000000080002b10 <syscall>:
}; */


void
syscall(void)
{
    80002b10:	1101                	addi	sp,sp,-32
    80002b12:	ec06                	sd	ra,24(sp)
    80002b14:	e822                	sd	s0,16(sp)
    80002b16:	e426                	sd	s1,8(sp)
    80002b18:	e04a                	sd	s2,0(sp)
    80002b1a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	e78080e7          	jalr	-392(ra) # 80001994 <myproc>
    80002b24:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b26:	05853903          	ld	s2,88(a0)
    80002b2a:	0a893783          	ld	a5,168(s2)
    80002b2e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b32:	37fd                	addiw	a5,a5,-1
    80002b34:	4759                	li	a4,22
    80002b36:	00f76f63          	bltu	a4,a5,80002b54 <syscall+0x44>
    80002b3a:	00369713          	slli	a4,a3,0x3
    80002b3e:	00006797          	auipc	a5,0x6
    80002b42:	8f278793          	addi	a5,a5,-1806 # 80008430 <syscalls>
    80002b46:	97ba                	add	a5,a5,a4
    80002b48:	639c                	ld	a5,0(a5)
    80002b4a:	c789                	beqz	a5,80002b54 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b4c:	9782                	jalr	a5
    80002b4e:	06a93823          	sd	a0,112(s2)
    80002b52:	a839                	j	80002b70 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b54:	15848613          	addi	a2,s1,344
    80002b58:	588c                	lw	a1,48(s1)
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	89e50513          	addi	a0,a0,-1890 # 800083f8 <states.1716+0x150>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a18080e7          	jalr	-1512(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b6a:	6cbc                	ld	a5,88(s1)
    80002b6c:	577d                	li	a4,-1
    80002b6e:	fbb8                	sd	a4,112(a5)
  }
/*
  if (p->mask & 1 << num) {
    printf("%d: syscall %s -> %d\n", p->pid, syscallnames[num], p->trapframe->a0); //print out in format: PID: syscall <name> -> <PID2>
  }*/
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6902                	ld	s2,0(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret

0000000080002b7c <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002b7c:	1101                	addi	sp,sp,-32
    80002b7e:	ec06                	sd	ra,24(sp)
    80002b80:	e822                	sd	s0,16(sp)
    80002b82:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b84:	fec40593          	addi	a1,s0,-20
    80002b88:	4501                	li	a0,0
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	f12080e7          	jalr	-238(ra) # 80002a9c <argint>
    return -1;
    80002b92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b94:	00054963          	bltz	a0,80002ba6 <sys_exit+0x2a>
  exit(n);
    80002b98:	fec42503          	lw	a0,-20(s0)
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	718080e7          	jalr	1816(ra) # 800022b4 <exit>
  return 0;  // not reached
    80002ba4:	4781                	li	a5,0
}
    80002ba6:	853e                	mv	a0,a5
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bb0:	1141                	addi	sp,sp,-16
    80002bb2:	e406                	sd	ra,8(sp)
    80002bb4:	e022                	sd	s0,0(sp)
    80002bb6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	ddc080e7          	jalr	-548(ra) # 80001994 <myproc>
}
    80002bc0:	5908                	lw	a0,48(a0)
    80002bc2:	60a2                	ld	ra,8(sp)
    80002bc4:	6402                	ld	s0,0(sp)
    80002bc6:	0141                	addi	sp,sp,16
    80002bc8:	8082                	ret

0000000080002bca <sys_fork>:

uint64
sys_fork(void)
{
    80002bca:	1141                	addi	sp,sp,-16
    80002bcc:	e406                	sd	ra,8(sp)
    80002bce:	e022                	sd	s0,0(sp)
    80002bd0:	0800                	addi	s0,sp,16
  return fork();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	190080e7          	jalr	400(ra) # 80001d62 <fork>
}
    80002bda:	60a2                	ld	ra,8(sp)
    80002bdc:	6402                	ld	s0,0(sp)
    80002bde:	0141                	addi	sp,sp,16
    80002be0:	8082                	ret

0000000080002be2 <sys_wait>:

uint64
sys_wait(void)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bea:	fe840593          	addi	a1,s0,-24
    80002bee:	4501                	li	a0,0
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	ece080e7          	jalr	-306(ra) # 80002abe <argaddr>
    80002bf8:	87aa                	mv	a5,a0
    return -1;
    80002bfa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bfc:	0007c863          	bltz	a5,80002c0c <sys_wait+0x2a>
  return wait(p);
    80002c00:	fe843503          	ld	a0,-24(s0)
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	4b8080e7          	jalr	1208(ra) # 800020bc <wait>
}
    80002c0c:	60e2                	ld	ra,24(sp)
    80002c0e:	6442                	ld	s0,16(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret

0000000080002c14 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c14:	7179                	addi	sp,sp,-48
    80002c16:	f406                	sd	ra,40(sp)
    80002c18:	f022                	sd	s0,32(sp)
    80002c1a:	ec26                	sd	s1,24(sp)
    80002c1c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c1e:	fdc40593          	addi	a1,s0,-36
    80002c22:	4501                	li	a0,0
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	e78080e7          	jalr	-392(ra) # 80002a9c <argint>
    80002c2c:	87aa                	mv	a5,a0
    return -1;
    80002c2e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c30:	0207c063          	bltz	a5,80002c50 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	d60080e7          	jalr	-672(ra) # 80001994 <myproc>
    80002c3c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c3e:	fdc42503          	lw	a0,-36(s0)
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	0ac080e7          	jalr	172(ra) # 80001cee <growproc>
    80002c4a:	00054863          	bltz	a0,80002c5a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c4e:	8526                	mv	a0,s1
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret
    return -1;
    80002c5a:	557d                	li	a0,-1
    80002c5c:	bfd5                	j	80002c50 <sys_sbrk+0x3c>

0000000080002c5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c5e:	7139                	addi	sp,sp,-64
    80002c60:	fc06                	sd	ra,56(sp)
    80002c62:	f822                	sd	s0,48(sp)
    80002c64:	f426                	sd	s1,40(sp)
    80002c66:	f04a                	sd	s2,32(sp)
    80002c68:	ec4e                	sd	s3,24(sp)
    80002c6a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c6c:	fcc40593          	addi	a1,s0,-52
    80002c70:	4501                	li	a0,0
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	e2a080e7          	jalr	-470(ra) # 80002a9c <argint>
    return -1;
    80002c7a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c7c:	06054563          	bltz	a0,80002ce6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c80:	00014517          	auipc	a0,0x14
    80002c84:	45050513          	addi	a0,a0,1104 # 800170d0 <tickslock>
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	f4e080e7          	jalr	-178(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002c90:	00006917          	auipc	s2,0x6
    80002c94:	3a092903          	lw	s2,928(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c98:	fcc42783          	lw	a5,-52(s0)
    80002c9c:	cf85                	beqz	a5,80002cd4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c9e:	00014997          	auipc	s3,0x14
    80002ca2:	43298993          	addi	s3,s3,1074 # 800170d0 <tickslock>
    80002ca6:	00006497          	auipc	s1,0x6
    80002caa:	38a48493          	addi	s1,s1,906 # 80009030 <ticks>
    if(myproc()->killed){
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	ce6080e7          	jalr	-794(ra) # 80001994 <myproc>
    80002cb6:	551c                	lw	a5,40(a0)
    80002cb8:	ef9d                	bnez	a5,80002cf6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cba:	85ce                	mv	a1,s3
    80002cbc:	8526                	mv	a0,s1
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	39a080e7          	jalr	922(ra) # 80002058 <sleep>
  while(ticks - ticks0 < n){
    80002cc6:	409c                	lw	a5,0(s1)
    80002cc8:	412787bb          	subw	a5,a5,s2
    80002ccc:	fcc42703          	lw	a4,-52(s0)
    80002cd0:	fce7efe3          	bltu	a5,a4,80002cae <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cd4:	00014517          	auipc	a0,0x14
    80002cd8:	3fc50513          	addi	a0,a0,1020 # 800170d0 <tickslock>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	fae080e7          	jalr	-82(ra) # 80000c8a <release>
  return 0;
    80002ce4:	4781                	li	a5,0
}
    80002ce6:	853e                	mv	a0,a5
    80002ce8:	70e2                	ld	ra,56(sp)
    80002cea:	7442                	ld	s0,48(sp)
    80002cec:	74a2                	ld	s1,40(sp)
    80002cee:	7902                	ld	s2,32(sp)
    80002cf0:	69e2                	ld	s3,24(sp)
    80002cf2:	6121                	addi	sp,sp,64
    80002cf4:	8082                	ret
      release(&tickslock);
    80002cf6:	00014517          	auipc	a0,0x14
    80002cfa:	3da50513          	addi	a0,a0,986 # 800170d0 <tickslock>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	f8c080e7          	jalr	-116(ra) # 80000c8a <release>
      return -1;
    80002d06:	57fd                	li	a5,-1
    80002d08:	bff9                	j	80002ce6 <sys_sleep+0x88>

0000000080002d0a <sys_kill>:

uint64
sys_kill(void)
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d12:	fec40593          	addi	a1,s0,-20
    80002d16:	4501                	li	a0,0
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	d84080e7          	jalr	-636(ra) # 80002a9c <argint>
    80002d20:	87aa                	mv	a5,a0
    return -1;
    80002d22:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d24:	0007c863          	bltz	a5,80002d34 <sys_kill+0x2a>
  return kill(pid);
    80002d28:	fec42503          	lw	a0,-20(s0)
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	65e080e7          	jalr	1630(ra) # 8000238a <kill>
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret

0000000080002d3c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d46:	00014517          	auipc	a0,0x14
    80002d4a:	38a50513          	addi	a0,a0,906 # 800170d0 <tickslock>
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	e88080e7          	jalr	-376(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d56:	00006497          	auipc	s1,0x6
    80002d5a:	2da4a483          	lw	s1,730(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d5e:	00014517          	auipc	a0,0x14
    80002d62:	37250513          	addi	a0,a0,882 # 800170d0 <tickslock>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	f24080e7          	jalr	-220(ra) # 80000c8a <release>
  return xticks;
}
    80002d6e:	02049513          	slli	a0,s1,0x20
    80002d72:	9101                	srli	a0,a0,0x20
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_time>:

// return real-time ticks
uint64
sys_time(void) {
    80002d7e:	1141                	addi	sp,sp,-16
    80002d80:	e422                	sd	s0,8(sp)
    80002d82:	0800                	addi	s0,sp,16
  return 0;
}
    80002d84:	4501                	li	a0,0
    80002d86:	6422                	ld	s0,8(sp)
    80002d88:	0141                	addi	sp,sp,16
    80002d8a:	8082                	ret

0000000080002d8c <sys_trace>:

uint64
sys_trace(void) {
    80002d8c:	7179                	addi	sp,sp,-48
    80002d8e:	f406                	sd	ra,40(sp)
    80002d90:	f022                	sd	s0,32(sp)
    80002d92:	ec26                	sd	s1,24(sp)
    80002d94:	1800                	addi	s0,sp,48
  int mask;
  struct proc *p = myproc();
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	bfe080e7          	jalr	-1026(ra) # 80001994 <myproc>
    80002d9e:	84aa                	mv	s1,a0

  if(argint(0, &mask) < 0) {
    80002da0:	fdc40593          	addi	a1,s0,-36
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	cf6080e7          	jalr	-778(ra) # 80002a9c <argint>
    80002dae:	00054b63          	bltz	a0,80002dc4 <sys_trace+0x38>
    return - 1;
  }
  p->mask = mask;
    80002db2:	fdc42783          	lw	a5,-36(s0)
    80002db6:	d8dc                	sw	a5,52(s1)
  return 0;
    80002db8:	4501                	li	a0,0
}
    80002dba:	70a2                	ld	ra,40(sp)
    80002dbc:	7402                	ld	s0,32(sp)
    80002dbe:	64e2                	ld	s1,24(sp)
    80002dc0:	6145                	addi	sp,sp,48
    80002dc2:	8082                	ret
    return - 1;
    80002dc4:	557d                	li	a0,-1
    80002dc6:	bfd5                	j	80002dba <sys_trace+0x2e>

0000000080002dc8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dc8:	7179                	addi	sp,sp,-48
    80002dca:	f406                	sd	ra,40(sp)
    80002dcc:	f022                	sd	s0,32(sp)
    80002dce:	ec26                	sd	s1,24(sp)
    80002dd0:	e84a                	sd	s2,16(sp)
    80002dd2:	e44e                	sd	s3,8(sp)
    80002dd4:	e052                	sd	s4,0(sp)
    80002dd6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dd8:	00005597          	auipc	a1,0x5
    80002ddc:	71858593          	addi	a1,a1,1816 # 800084f0 <syscalls+0xc0>
    80002de0:	00014517          	auipc	a0,0x14
    80002de4:	30850513          	addi	a0,a0,776 # 800170e8 <bcache>
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	d5e080e7          	jalr	-674(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002df0:	0001c797          	auipc	a5,0x1c
    80002df4:	2f878793          	addi	a5,a5,760 # 8001f0e8 <bcache+0x8000>
    80002df8:	0001c717          	auipc	a4,0x1c
    80002dfc:	55870713          	addi	a4,a4,1368 # 8001f350 <bcache+0x8268>
    80002e00:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e04:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e08:	00014497          	auipc	s1,0x14
    80002e0c:	2f848493          	addi	s1,s1,760 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e10:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e12:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e14:	00005a17          	auipc	s4,0x5
    80002e18:	6e4a0a13          	addi	s4,s4,1764 # 800084f8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002e1c:	2b893783          	ld	a5,696(s2)
    80002e20:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e22:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e26:	85d2                	mv	a1,s4
    80002e28:	01048513          	addi	a0,s1,16
    80002e2c:	00001097          	auipc	ra,0x1
    80002e30:	4bc080e7          	jalr	1212(ra) # 800042e8 <initsleeplock>
    bcache.head.next->prev = b;
    80002e34:	2b893783          	ld	a5,696(s2)
    80002e38:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e3a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e3e:	45848493          	addi	s1,s1,1112
    80002e42:	fd349de3          	bne	s1,s3,80002e1c <binit+0x54>
  }
}
    80002e46:	70a2                	ld	ra,40(sp)
    80002e48:	7402                	ld	s0,32(sp)
    80002e4a:	64e2                	ld	s1,24(sp)
    80002e4c:	6942                	ld	s2,16(sp)
    80002e4e:	69a2                	ld	s3,8(sp)
    80002e50:	6a02                	ld	s4,0(sp)
    80002e52:	6145                	addi	sp,sp,48
    80002e54:	8082                	ret

0000000080002e56 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e56:	7179                	addi	sp,sp,-48
    80002e58:	f406                	sd	ra,40(sp)
    80002e5a:	f022                	sd	s0,32(sp)
    80002e5c:	ec26                	sd	s1,24(sp)
    80002e5e:	e84a                	sd	s2,16(sp)
    80002e60:	e44e                	sd	s3,8(sp)
    80002e62:	1800                	addi	s0,sp,48
    80002e64:	89aa                	mv	s3,a0
    80002e66:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e68:	00014517          	auipc	a0,0x14
    80002e6c:	28050513          	addi	a0,a0,640 # 800170e8 <bcache>
    80002e70:	ffffe097          	auipc	ra,0xffffe
    80002e74:	d66080e7          	jalr	-666(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e78:	0001c497          	auipc	s1,0x1c
    80002e7c:	5284b483          	ld	s1,1320(s1) # 8001f3a0 <bcache+0x82b8>
    80002e80:	0001c797          	auipc	a5,0x1c
    80002e84:	4d078793          	addi	a5,a5,1232 # 8001f350 <bcache+0x8268>
    80002e88:	02f48f63          	beq	s1,a5,80002ec6 <bread+0x70>
    80002e8c:	873e                	mv	a4,a5
    80002e8e:	a021                	j	80002e96 <bread+0x40>
    80002e90:	68a4                	ld	s1,80(s1)
    80002e92:	02e48a63          	beq	s1,a4,80002ec6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e96:	449c                	lw	a5,8(s1)
    80002e98:	ff379ce3          	bne	a5,s3,80002e90 <bread+0x3a>
    80002e9c:	44dc                	lw	a5,12(s1)
    80002e9e:	ff2799e3          	bne	a5,s2,80002e90 <bread+0x3a>
      b->refcnt++;
    80002ea2:	40bc                	lw	a5,64(s1)
    80002ea4:	2785                	addiw	a5,a5,1
    80002ea6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	24050513          	addi	a0,a0,576 # 800170e8 <bcache>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	dda080e7          	jalr	-550(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002eb8:	01048513          	addi	a0,s1,16
    80002ebc:	00001097          	auipc	ra,0x1
    80002ec0:	466080e7          	jalr	1126(ra) # 80004322 <acquiresleep>
      return b;
    80002ec4:	a8b9                	j	80002f22 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ec6:	0001c497          	auipc	s1,0x1c
    80002eca:	4d24b483          	ld	s1,1234(s1) # 8001f398 <bcache+0x82b0>
    80002ece:	0001c797          	auipc	a5,0x1c
    80002ed2:	48278793          	addi	a5,a5,1154 # 8001f350 <bcache+0x8268>
    80002ed6:	00f48863          	beq	s1,a5,80002ee6 <bread+0x90>
    80002eda:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002edc:	40bc                	lw	a5,64(s1)
    80002ede:	cf81                	beqz	a5,80002ef6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ee0:	64a4                	ld	s1,72(s1)
    80002ee2:	fee49de3          	bne	s1,a4,80002edc <bread+0x86>
  panic("bget: no buffers");
    80002ee6:	00005517          	auipc	a0,0x5
    80002eea:	61a50513          	addi	a0,a0,1562 # 80008500 <syscalls+0xd0>
    80002eee:	ffffd097          	auipc	ra,0xffffd
    80002ef2:	642080e7          	jalr	1602(ra) # 80000530 <panic>
      b->dev = dev;
    80002ef6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002efa:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002efe:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f02:	4785                	li	a5,1
    80002f04:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f06:	00014517          	auipc	a0,0x14
    80002f0a:	1e250513          	addi	a0,a0,482 # 800170e8 <bcache>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	d7c080e7          	jalr	-644(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f16:	01048513          	addi	a0,s1,16
    80002f1a:	00001097          	auipc	ra,0x1
    80002f1e:	408080e7          	jalr	1032(ra) # 80004322 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f22:	409c                	lw	a5,0(s1)
    80002f24:	cb89                	beqz	a5,80002f36 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f26:	8526                	mv	a0,s1
    80002f28:	70a2                	ld	ra,40(sp)
    80002f2a:	7402                	ld	s0,32(sp)
    80002f2c:	64e2                	ld	s1,24(sp)
    80002f2e:	6942                	ld	s2,16(sp)
    80002f30:	69a2                	ld	s3,8(sp)
    80002f32:	6145                	addi	sp,sp,48
    80002f34:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f36:	4581                	li	a1,0
    80002f38:	8526                	mv	a0,s1
    80002f3a:	00003097          	auipc	ra,0x3
    80002f3e:	f0c080e7          	jalr	-244(ra) # 80005e46 <virtio_disk_rw>
    b->valid = 1;
    80002f42:	4785                	li	a5,1
    80002f44:	c09c                	sw	a5,0(s1)
  return b;
    80002f46:	b7c5                	j	80002f26 <bread+0xd0>

0000000080002f48 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	e426                	sd	s1,8(sp)
    80002f50:	1000                	addi	s0,sp,32
    80002f52:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f54:	0541                	addi	a0,a0,16
    80002f56:	00001097          	auipc	ra,0x1
    80002f5a:	466080e7          	jalr	1126(ra) # 800043bc <holdingsleep>
    80002f5e:	cd01                	beqz	a0,80002f76 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f60:	4585                	li	a1,1
    80002f62:	8526                	mv	a0,s1
    80002f64:	00003097          	auipc	ra,0x3
    80002f68:	ee2080e7          	jalr	-286(ra) # 80005e46 <virtio_disk_rw>
}
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	64a2                	ld	s1,8(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret
    panic("bwrite");
    80002f76:	00005517          	auipc	a0,0x5
    80002f7a:	5a250513          	addi	a0,a0,1442 # 80008518 <syscalls+0xe8>
    80002f7e:	ffffd097          	auipc	ra,0xffffd
    80002f82:	5b2080e7          	jalr	1458(ra) # 80000530 <panic>

0000000080002f86 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f86:	1101                	addi	sp,sp,-32
    80002f88:	ec06                	sd	ra,24(sp)
    80002f8a:	e822                	sd	s0,16(sp)
    80002f8c:	e426                	sd	s1,8(sp)
    80002f8e:	e04a                	sd	s2,0(sp)
    80002f90:	1000                	addi	s0,sp,32
    80002f92:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f94:	01050913          	addi	s2,a0,16
    80002f98:	854a                	mv	a0,s2
    80002f9a:	00001097          	auipc	ra,0x1
    80002f9e:	422080e7          	jalr	1058(ra) # 800043bc <holdingsleep>
    80002fa2:	c92d                	beqz	a0,80003014 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fa4:	854a                	mv	a0,s2
    80002fa6:	00001097          	auipc	ra,0x1
    80002faa:	3d2080e7          	jalr	978(ra) # 80004378 <releasesleep>

  acquire(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	13a50513          	addi	a0,a0,314 # 800170e8 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	c20080e7          	jalr	-992(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002fbe:	40bc                	lw	a5,64(s1)
    80002fc0:	37fd                	addiw	a5,a5,-1
    80002fc2:	0007871b          	sext.w	a4,a5
    80002fc6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fc8:	eb05                	bnez	a4,80002ff8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fca:	68bc                	ld	a5,80(s1)
    80002fcc:	64b8                	ld	a4,72(s1)
    80002fce:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fd0:	64bc                	ld	a5,72(s1)
    80002fd2:	68b8                	ld	a4,80(s1)
    80002fd4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fd6:	0001c797          	auipc	a5,0x1c
    80002fda:	11278793          	addi	a5,a5,274 # 8001f0e8 <bcache+0x8000>
    80002fde:	2b87b703          	ld	a4,696(a5)
    80002fe2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fe4:	0001c717          	auipc	a4,0x1c
    80002fe8:	36c70713          	addi	a4,a4,876 # 8001f350 <bcache+0x8268>
    80002fec:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fee:	2b87b703          	ld	a4,696(a5)
    80002ff2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002ff4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002ff8:	00014517          	auipc	a0,0x14
    80002ffc:	0f050513          	addi	a0,a0,240 # 800170e8 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	c8a080e7          	jalr	-886(ra) # 80000c8a <release>
}
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6902                	ld	s2,0(sp)
    80003010:	6105                	addi	sp,sp,32
    80003012:	8082                	ret
    panic("brelse");
    80003014:	00005517          	auipc	a0,0x5
    80003018:	50c50513          	addi	a0,a0,1292 # 80008520 <syscalls+0xf0>
    8000301c:	ffffd097          	auipc	ra,0xffffd
    80003020:	514080e7          	jalr	1300(ra) # 80000530 <panic>

0000000080003024 <bpin>:

void
bpin(struct buf *b) {
    80003024:	1101                	addi	sp,sp,-32
    80003026:	ec06                	sd	ra,24(sp)
    80003028:	e822                	sd	s0,16(sp)
    8000302a:	e426                	sd	s1,8(sp)
    8000302c:	1000                	addi	s0,sp,32
    8000302e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003030:	00014517          	auipc	a0,0x14
    80003034:	0b850513          	addi	a0,a0,184 # 800170e8 <bcache>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	b9e080e7          	jalr	-1122(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003040:	40bc                	lw	a5,64(s1)
    80003042:	2785                	addiw	a5,a5,1
    80003044:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	0a250513          	addi	a0,a0,162 # 800170e8 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	c3c080e7          	jalr	-964(ra) # 80000c8a <release>
}
    80003056:	60e2                	ld	ra,24(sp)
    80003058:	6442                	ld	s0,16(sp)
    8000305a:	64a2                	ld	s1,8(sp)
    8000305c:	6105                	addi	sp,sp,32
    8000305e:	8082                	ret

0000000080003060 <bunpin>:

void
bunpin(struct buf *b) {
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	1000                	addi	s0,sp,32
    8000306a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	07c50513          	addi	a0,a0,124 # 800170e8 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	b62080e7          	jalr	-1182(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000307c:	40bc                	lw	a5,64(s1)
    8000307e:	37fd                	addiw	a5,a5,-1
    80003080:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003082:	00014517          	auipc	a0,0x14
    80003086:	06650513          	addi	a0,a0,102 # 800170e8 <bcache>
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	c00080e7          	jalr	-1024(ra) # 80000c8a <release>
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	e04a                	sd	s2,0(sp)
    800030a6:	1000                	addi	s0,sp,32
    800030a8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030aa:	00d5d59b          	srliw	a1,a1,0xd
    800030ae:	0001c797          	auipc	a5,0x1c
    800030b2:	7167a783          	lw	a5,1814(a5) # 8001f7c4 <sb+0x1c>
    800030b6:	9dbd                	addw	a1,a1,a5
    800030b8:	00000097          	auipc	ra,0x0
    800030bc:	d9e080e7          	jalr	-610(ra) # 80002e56 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030c0:	0074f713          	andi	a4,s1,7
    800030c4:	4785                	li	a5,1
    800030c6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030ca:	14ce                	slli	s1,s1,0x33
    800030cc:	90d9                	srli	s1,s1,0x36
    800030ce:	00950733          	add	a4,a0,s1
    800030d2:	05874703          	lbu	a4,88(a4)
    800030d6:	00e7f6b3          	and	a3,a5,a4
    800030da:	c69d                	beqz	a3,80003108 <bfree+0x6c>
    800030dc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030de:	94aa                	add	s1,s1,a0
    800030e0:	fff7c793          	not	a5,a5
    800030e4:	8ff9                	and	a5,a5,a4
    800030e6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030ea:	00001097          	auipc	ra,0x1
    800030ee:	118080e7          	jalr	280(ra) # 80004202 <log_write>
  brelse(bp);
    800030f2:	854a                	mv	a0,s2
    800030f4:	00000097          	auipc	ra,0x0
    800030f8:	e92080e7          	jalr	-366(ra) # 80002f86 <brelse>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6902                	ld	s2,0(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret
    panic("freeing free block");
    80003108:	00005517          	auipc	a0,0x5
    8000310c:	42050513          	addi	a0,a0,1056 # 80008528 <syscalls+0xf8>
    80003110:	ffffd097          	auipc	ra,0xffffd
    80003114:	420080e7          	jalr	1056(ra) # 80000530 <panic>

0000000080003118 <balloc>:
{
    80003118:	711d                	addi	sp,sp,-96
    8000311a:	ec86                	sd	ra,88(sp)
    8000311c:	e8a2                	sd	s0,80(sp)
    8000311e:	e4a6                	sd	s1,72(sp)
    80003120:	e0ca                	sd	s2,64(sp)
    80003122:	fc4e                	sd	s3,56(sp)
    80003124:	f852                	sd	s4,48(sp)
    80003126:	f456                	sd	s5,40(sp)
    80003128:	f05a                	sd	s6,32(sp)
    8000312a:	ec5e                	sd	s7,24(sp)
    8000312c:	e862                	sd	s8,16(sp)
    8000312e:	e466                	sd	s9,8(sp)
    80003130:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003132:	0001c797          	auipc	a5,0x1c
    80003136:	67a7a783          	lw	a5,1658(a5) # 8001f7ac <sb+0x4>
    8000313a:	cbd1                	beqz	a5,800031ce <balloc+0xb6>
    8000313c:	8baa                	mv	s7,a0
    8000313e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003140:	0001cb17          	auipc	s6,0x1c
    80003144:	668b0b13          	addi	s6,s6,1640 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003148:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000314a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000314c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000314e:	6c89                	lui	s9,0x2
    80003150:	a831                	j	8000316c <balloc+0x54>
    brelse(bp);
    80003152:	854a                	mv	a0,s2
    80003154:	00000097          	auipc	ra,0x0
    80003158:	e32080e7          	jalr	-462(ra) # 80002f86 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000315c:	015c87bb          	addw	a5,s9,s5
    80003160:	00078a9b          	sext.w	s5,a5
    80003164:	004b2703          	lw	a4,4(s6)
    80003168:	06eaf363          	bgeu	s5,a4,800031ce <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000316c:	41fad79b          	sraiw	a5,s5,0x1f
    80003170:	0137d79b          	srliw	a5,a5,0x13
    80003174:	015787bb          	addw	a5,a5,s5
    80003178:	40d7d79b          	sraiw	a5,a5,0xd
    8000317c:	01cb2583          	lw	a1,28(s6)
    80003180:	9dbd                	addw	a1,a1,a5
    80003182:	855e                	mv	a0,s7
    80003184:	00000097          	auipc	ra,0x0
    80003188:	cd2080e7          	jalr	-814(ra) # 80002e56 <bread>
    8000318c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318e:	004b2503          	lw	a0,4(s6)
    80003192:	000a849b          	sext.w	s1,s5
    80003196:	8662                	mv	a2,s8
    80003198:	faa4fde3          	bgeu	s1,a0,80003152 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000319c:	41f6579b          	sraiw	a5,a2,0x1f
    800031a0:	01d7d69b          	srliw	a3,a5,0x1d
    800031a4:	00c6873b          	addw	a4,a3,a2
    800031a8:	00777793          	andi	a5,a4,7
    800031ac:	9f95                	subw	a5,a5,a3
    800031ae:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031b2:	4037571b          	sraiw	a4,a4,0x3
    800031b6:	00e906b3          	add	a3,s2,a4
    800031ba:	0586c683          	lbu	a3,88(a3)
    800031be:	00d7f5b3          	and	a1,a5,a3
    800031c2:	cd91                	beqz	a1,800031de <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c4:	2605                	addiw	a2,a2,1
    800031c6:	2485                	addiw	s1,s1,1
    800031c8:	fd4618e3          	bne	a2,s4,80003198 <balloc+0x80>
    800031cc:	b759                	j	80003152 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031ce:	00005517          	auipc	a0,0x5
    800031d2:	37250513          	addi	a0,a0,882 # 80008540 <syscalls+0x110>
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	35a080e7          	jalr	858(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031de:	974a                	add	a4,a4,s2
    800031e0:	8fd5                	or	a5,a5,a3
    800031e2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031e6:	854a                	mv	a0,s2
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	01a080e7          	jalr	26(ra) # 80004202 <log_write>
        brelse(bp);
    800031f0:	854a                	mv	a0,s2
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	d94080e7          	jalr	-620(ra) # 80002f86 <brelse>
  bp = bread(dev, bno);
    800031fa:	85a6                	mv	a1,s1
    800031fc:	855e                	mv	a0,s7
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	c58080e7          	jalr	-936(ra) # 80002e56 <bread>
    80003206:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003208:	40000613          	li	a2,1024
    8000320c:	4581                	li	a1,0
    8000320e:	05850513          	addi	a0,a0,88
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	ac0080e7          	jalr	-1344(ra) # 80000cd2 <memset>
  log_write(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	fe6080e7          	jalr	-26(ra) # 80004202 <log_write>
  brelse(bp);
    80003224:	854a                	mv	a0,s2
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	d60080e7          	jalr	-672(ra) # 80002f86 <brelse>
}
    8000322e:	8526                	mv	a0,s1
    80003230:	60e6                	ld	ra,88(sp)
    80003232:	6446                	ld	s0,80(sp)
    80003234:	64a6                	ld	s1,72(sp)
    80003236:	6906                	ld	s2,64(sp)
    80003238:	79e2                	ld	s3,56(sp)
    8000323a:	7a42                	ld	s4,48(sp)
    8000323c:	7aa2                	ld	s5,40(sp)
    8000323e:	7b02                	ld	s6,32(sp)
    80003240:	6be2                	ld	s7,24(sp)
    80003242:	6c42                	ld	s8,16(sp)
    80003244:	6ca2                	ld	s9,8(sp)
    80003246:	6125                	addi	sp,sp,96
    80003248:	8082                	ret

000000008000324a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000324a:	7179                	addi	sp,sp,-48
    8000324c:	f406                	sd	ra,40(sp)
    8000324e:	f022                	sd	s0,32(sp)
    80003250:	ec26                	sd	s1,24(sp)
    80003252:	e84a                	sd	s2,16(sp)
    80003254:	e44e                	sd	s3,8(sp)
    80003256:	e052                	sd	s4,0(sp)
    80003258:	1800                	addi	s0,sp,48
    8000325a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000325c:	47ad                	li	a5,11
    8000325e:	04b7fe63          	bgeu	a5,a1,800032ba <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003262:	ff45849b          	addiw	s1,a1,-12
    80003266:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000326a:	0ff00793          	li	a5,255
    8000326e:	0ae7e363          	bltu	a5,a4,80003314 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003272:	08052583          	lw	a1,128(a0)
    80003276:	c5ad                	beqz	a1,800032e0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003278:	00092503          	lw	a0,0(s2)
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	bda080e7          	jalr	-1062(ra) # 80002e56 <bread>
    80003284:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003286:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000328a:	02049593          	slli	a1,s1,0x20
    8000328e:	9181                	srli	a1,a1,0x20
    80003290:	058a                	slli	a1,a1,0x2
    80003292:	00b784b3          	add	s1,a5,a1
    80003296:	0004a983          	lw	s3,0(s1)
    8000329a:	04098d63          	beqz	s3,800032f4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000329e:	8552                	mv	a0,s4
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	ce6080e7          	jalr	-794(ra) # 80002f86 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032a8:	854e                	mv	a0,s3
    800032aa:	70a2                	ld	ra,40(sp)
    800032ac:	7402                	ld	s0,32(sp)
    800032ae:	64e2                	ld	s1,24(sp)
    800032b0:	6942                	ld	s2,16(sp)
    800032b2:	69a2                	ld	s3,8(sp)
    800032b4:	6a02                	ld	s4,0(sp)
    800032b6:	6145                	addi	sp,sp,48
    800032b8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032ba:	02059493          	slli	s1,a1,0x20
    800032be:	9081                	srli	s1,s1,0x20
    800032c0:	048a                	slli	s1,s1,0x2
    800032c2:	94aa                	add	s1,s1,a0
    800032c4:	0504a983          	lw	s3,80(s1)
    800032c8:	fe0990e3          	bnez	s3,800032a8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032cc:	4108                	lw	a0,0(a0)
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	e4a080e7          	jalr	-438(ra) # 80003118 <balloc>
    800032d6:	0005099b          	sext.w	s3,a0
    800032da:	0534a823          	sw	s3,80(s1)
    800032de:	b7e9                	j	800032a8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032e0:	4108                	lw	a0,0(a0)
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	e36080e7          	jalr	-458(ra) # 80003118 <balloc>
    800032ea:	0005059b          	sext.w	a1,a0
    800032ee:	08b92023          	sw	a1,128(s2)
    800032f2:	b759                	j	80003278 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032f4:	00092503          	lw	a0,0(s2)
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	e20080e7          	jalr	-480(ra) # 80003118 <balloc>
    80003300:	0005099b          	sext.w	s3,a0
    80003304:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003308:	8552                	mv	a0,s4
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	ef8080e7          	jalr	-264(ra) # 80004202 <log_write>
    80003312:	b771                	j	8000329e <bmap+0x54>
  panic("bmap: out of range");
    80003314:	00005517          	auipc	a0,0x5
    80003318:	24450513          	addi	a0,a0,580 # 80008558 <syscalls+0x128>
    8000331c:	ffffd097          	auipc	ra,0xffffd
    80003320:	214080e7          	jalr	532(ra) # 80000530 <panic>

0000000080003324 <iget>:
{
    80003324:	7179                	addi	sp,sp,-48
    80003326:	f406                	sd	ra,40(sp)
    80003328:	f022                	sd	s0,32(sp)
    8000332a:	ec26                	sd	s1,24(sp)
    8000332c:	e84a                	sd	s2,16(sp)
    8000332e:	e44e                	sd	s3,8(sp)
    80003330:	e052                	sd	s4,0(sp)
    80003332:	1800                	addi	s0,sp,48
    80003334:	89aa                	mv	s3,a0
    80003336:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003338:	0001c517          	auipc	a0,0x1c
    8000333c:	49050513          	addi	a0,a0,1168 # 8001f7c8 <itable>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	896080e7          	jalr	-1898(ra) # 80000bd6 <acquire>
  empty = 0;
    80003348:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000334a:	0001c497          	auipc	s1,0x1c
    8000334e:	49648493          	addi	s1,s1,1174 # 8001f7e0 <itable+0x18>
    80003352:	0001e697          	auipc	a3,0x1e
    80003356:	f1e68693          	addi	a3,a3,-226 # 80021270 <log>
    8000335a:	a039                	j	80003368 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335c:	02090b63          	beqz	s2,80003392 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003360:	08848493          	addi	s1,s1,136
    80003364:	02d48a63          	beq	s1,a3,80003398 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003368:	449c                	lw	a5,8(s1)
    8000336a:	fef059e3          	blez	a5,8000335c <iget+0x38>
    8000336e:	4098                	lw	a4,0(s1)
    80003370:	ff3716e3          	bne	a4,s3,8000335c <iget+0x38>
    80003374:	40d8                	lw	a4,4(s1)
    80003376:	ff4713e3          	bne	a4,s4,8000335c <iget+0x38>
      ip->ref++;
    8000337a:	2785                	addiw	a5,a5,1
    8000337c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000337e:	0001c517          	auipc	a0,0x1c
    80003382:	44a50513          	addi	a0,a0,1098 # 8001f7c8 <itable>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	904080e7          	jalr	-1788(ra) # 80000c8a <release>
      return ip;
    8000338e:	8926                	mv	s2,s1
    80003390:	a03d                	j	800033be <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003392:	f7f9                	bnez	a5,80003360 <iget+0x3c>
    80003394:	8926                	mv	s2,s1
    80003396:	b7e9                	j	80003360 <iget+0x3c>
  if(empty == 0)
    80003398:	02090c63          	beqz	s2,800033d0 <iget+0xac>
  ip->dev = dev;
    8000339c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033a0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033a4:	4785                	li	a5,1
    800033a6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033aa:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033ae:	0001c517          	auipc	a0,0x1c
    800033b2:	41a50513          	addi	a0,a0,1050 # 8001f7c8 <itable>
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <release>
}
    800033be:	854a                	mv	a0,s2
    800033c0:	70a2                	ld	ra,40(sp)
    800033c2:	7402                	ld	s0,32(sp)
    800033c4:	64e2                	ld	s1,24(sp)
    800033c6:	6942                	ld	s2,16(sp)
    800033c8:	69a2                	ld	s3,8(sp)
    800033ca:	6a02                	ld	s4,0(sp)
    800033cc:	6145                	addi	sp,sp,48
    800033ce:	8082                	ret
    panic("iget: no inodes");
    800033d0:	00005517          	auipc	a0,0x5
    800033d4:	1a050513          	addi	a0,a0,416 # 80008570 <syscalls+0x140>
    800033d8:	ffffd097          	auipc	ra,0xffffd
    800033dc:	158080e7          	jalr	344(ra) # 80000530 <panic>

00000000800033e0 <fsinit>:
fsinit(int dev) {
    800033e0:	7179                	addi	sp,sp,-48
    800033e2:	f406                	sd	ra,40(sp)
    800033e4:	f022                	sd	s0,32(sp)
    800033e6:	ec26                	sd	s1,24(sp)
    800033e8:	e84a                	sd	s2,16(sp)
    800033ea:	e44e                	sd	s3,8(sp)
    800033ec:	1800                	addi	s0,sp,48
    800033ee:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033f0:	4585                	li	a1,1
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	a64080e7          	jalr	-1436(ra) # 80002e56 <bread>
    800033fa:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033fc:	0001c997          	auipc	s3,0x1c
    80003400:	3ac98993          	addi	s3,s3,940 # 8001f7a8 <sb>
    80003404:	02000613          	li	a2,32
    80003408:	05850593          	addi	a1,a0,88
    8000340c:	854e                	mv	a0,s3
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	924080e7          	jalr	-1756(ra) # 80000d32 <memmove>
  brelse(bp);
    80003416:	8526                	mv	a0,s1
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	b6e080e7          	jalr	-1170(ra) # 80002f86 <brelse>
  if(sb.magic != FSMAGIC)
    80003420:	0009a703          	lw	a4,0(s3)
    80003424:	102037b7          	lui	a5,0x10203
    80003428:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000342c:	02f71263          	bne	a4,a5,80003450 <fsinit+0x70>
  initlog(dev, &sb);
    80003430:	0001c597          	auipc	a1,0x1c
    80003434:	37858593          	addi	a1,a1,888 # 8001f7a8 <sb>
    80003438:	854a                	mv	a0,s2
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	b4c080e7          	jalr	-1204(ra) # 80003f86 <initlog>
}
    80003442:	70a2                	ld	ra,40(sp)
    80003444:	7402                	ld	s0,32(sp)
    80003446:	64e2                	ld	s1,24(sp)
    80003448:	6942                	ld	s2,16(sp)
    8000344a:	69a2                	ld	s3,8(sp)
    8000344c:	6145                	addi	sp,sp,48
    8000344e:	8082                	ret
    panic("invalid file system");
    80003450:	00005517          	auipc	a0,0x5
    80003454:	13050513          	addi	a0,a0,304 # 80008580 <syscalls+0x150>
    80003458:	ffffd097          	auipc	ra,0xffffd
    8000345c:	0d8080e7          	jalr	216(ra) # 80000530 <panic>

0000000080003460 <iinit>:
{
    80003460:	7179                	addi	sp,sp,-48
    80003462:	f406                	sd	ra,40(sp)
    80003464:	f022                	sd	s0,32(sp)
    80003466:	ec26                	sd	s1,24(sp)
    80003468:	e84a                	sd	s2,16(sp)
    8000346a:	e44e                	sd	s3,8(sp)
    8000346c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000346e:	00005597          	auipc	a1,0x5
    80003472:	12a58593          	addi	a1,a1,298 # 80008598 <syscalls+0x168>
    80003476:	0001c517          	auipc	a0,0x1c
    8000347a:	35250513          	addi	a0,a0,850 # 8001f7c8 <itable>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	6c8080e7          	jalr	1736(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003486:	0001c497          	auipc	s1,0x1c
    8000348a:	36a48493          	addi	s1,s1,874 # 8001f7f0 <itable+0x28>
    8000348e:	0001e997          	auipc	s3,0x1e
    80003492:	df298993          	addi	s3,s3,-526 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003496:	00005917          	auipc	s2,0x5
    8000349a:	10a90913          	addi	s2,s2,266 # 800085a0 <syscalls+0x170>
    8000349e:	85ca                	mv	a1,s2
    800034a0:	8526                	mv	a0,s1
    800034a2:	00001097          	auipc	ra,0x1
    800034a6:	e46080e7          	jalr	-442(ra) # 800042e8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034aa:	08848493          	addi	s1,s1,136
    800034ae:	ff3498e3          	bne	s1,s3,8000349e <iinit+0x3e>
}
    800034b2:	70a2                	ld	ra,40(sp)
    800034b4:	7402                	ld	s0,32(sp)
    800034b6:	64e2                	ld	s1,24(sp)
    800034b8:	6942                	ld	s2,16(sp)
    800034ba:	69a2                	ld	s3,8(sp)
    800034bc:	6145                	addi	sp,sp,48
    800034be:	8082                	ret

00000000800034c0 <ialloc>:
{
    800034c0:	715d                	addi	sp,sp,-80
    800034c2:	e486                	sd	ra,72(sp)
    800034c4:	e0a2                	sd	s0,64(sp)
    800034c6:	fc26                	sd	s1,56(sp)
    800034c8:	f84a                	sd	s2,48(sp)
    800034ca:	f44e                	sd	s3,40(sp)
    800034cc:	f052                	sd	s4,32(sp)
    800034ce:	ec56                	sd	s5,24(sp)
    800034d0:	e85a                	sd	s6,16(sp)
    800034d2:	e45e                	sd	s7,8(sp)
    800034d4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034d6:	0001c717          	auipc	a4,0x1c
    800034da:	2de72703          	lw	a4,734(a4) # 8001f7b4 <sb+0xc>
    800034de:	4785                	li	a5,1
    800034e0:	04e7fa63          	bgeu	a5,a4,80003534 <ialloc+0x74>
    800034e4:	8aaa                	mv	s5,a0
    800034e6:	8bae                	mv	s7,a1
    800034e8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034ea:	0001ca17          	auipc	s4,0x1c
    800034ee:	2bea0a13          	addi	s4,s4,702 # 8001f7a8 <sb>
    800034f2:	00048b1b          	sext.w	s6,s1
    800034f6:	0044d593          	srli	a1,s1,0x4
    800034fa:	018a2783          	lw	a5,24(s4)
    800034fe:	9dbd                	addw	a1,a1,a5
    80003500:	8556                	mv	a0,s5
    80003502:	00000097          	auipc	ra,0x0
    80003506:	954080e7          	jalr	-1708(ra) # 80002e56 <bread>
    8000350a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000350c:	05850993          	addi	s3,a0,88
    80003510:	00f4f793          	andi	a5,s1,15
    80003514:	079a                	slli	a5,a5,0x6
    80003516:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003518:	00099783          	lh	a5,0(s3)
    8000351c:	c785                	beqz	a5,80003544 <ialloc+0x84>
    brelse(bp);
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	a68080e7          	jalr	-1432(ra) # 80002f86 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003526:	0485                	addi	s1,s1,1
    80003528:	00ca2703          	lw	a4,12(s4)
    8000352c:	0004879b          	sext.w	a5,s1
    80003530:	fce7e1e3          	bltu	a5,a4,800034f2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	07450513          	addi	a0,a0,116 # 800085a8 <syscalls+0x178>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	ff4080e7          	jalr	-12(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    80003544:	04000613          	li	a2,64
    80003548:	4581                	li	a1,0
    8000354a:	854e                	mv	a0,s3
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	786080e7          	jalr	1926(ra) # 80000cd2 <memset>
      dip->type = type;
    80003554:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003558:	854a                	mv	a0,s2
    8000355a:	00001097          	auipc	ra,0x1
    8000355e:	ca8080e7          	jalr	-856(ra) # 80004202 <log_write>
      brelse(bp);
    80003562:	854a                	mv	a0,s2
    80003564:	00000097          	auipc	ra,0x0
    80003568:	a22080e7          	jalr	-1502(ra) # 80002f86 <brelse>
      return iget(dev, inum);
    8000356c:	85da                	mv	a1,s6
    8000356e:	8556                	mv	a0,s5
    80003570:	00000097          	auipc	ra,0x0
    80003574:	db4080e7          	jalr	-588(ra) # 80003324 <iget>
}
    80003578:	60a6                	ld	ra,72(sp)
    8000357a:	6406                	ld	s0,64(sp)
    8000357c:	74e2                	ld	s1,56(sp)
    8000357e:	7942                	ld	s2,48(sp)
    80003580:	79a2                	ld	s3,40(sp)
    80003582:	7a02                	ld	s4,32(sp)
    80003584:	6ae2                	ld	s5,24(sp)
    80003586:	6b42                	ld	s6,16(sp)
    80003588:	6ba2                	ld	s7,8(sp)
    8000358a:	6161                	addi	sp,sp,80
    8000358c:	8082                	ret

000000008000358e <iupdate>:
{
    8000358e:	1101                	addi	sp,sp,-32
    80003590:	ec06                	sd	ra,24(sp)
    80003592:	e822                	sd	s0,16(sp)
    80003594:	e426                	sd	s1,8(sp)
    80003596:	e04a                	sd	s2,0(sp)
    80003598:	1000                	addi	s0,sp,32
    8000359a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000359c:	415c                	lw	a5,4(a0)
    8000359e:	0047d79b          	srliw	a5,a5,0x4
    800035a2:	0001c597          	auipc	a1,0x1c
    800035a6:	21e5a583          	lw	a1,542(a1) # 8001f7c0 <sb+0x18>
    800035aa:	9dbd                	addw	a1,a1,a5
    800035ac:	4108                	lw	a0,0(a0)
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	8a8080e7          	jalr	-1880(ra) # 80002e56 <bread>
    800035b6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035b8:	05850793          	addi	a5,a0,88
    800035bc:	40c8                	lw	a0,4(s1)
    800035be:	893d                	andi	a0,a0,15
    800035c0:	051a                	slli	a0,a0,0x6
    800035c2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035c4:	04449703          	lh	a4,68(s1)
    800035c8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035cc:	04649703          	lh	a4,70(s1)
    800035d0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035d4:	04849703          	lh	a4,72(s1)
    800035d8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035dc:	04a49703          	lh	a4,74(s1)
    800035e0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035e4:	44f8                	lw	a4,76(s1)
    800035e6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035e8:	03400613          	li	a2,52
    800035ec:	05048593          	addi	a1,s1,80
    800035f0:	0531                	addi	a0,a0,12
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	740080e7          	jalr	1856(ra) # 80000d32 <memmove>
  log_write(bp);
    800035fa:	854a                	mv	a0,s2
    800035fc:	00001097          	auipc	ra,0x1
    80003600:	c06080e7          	jalr	-1018(ra) # 80004202 <log_write>
  brelse(bp);
    80003604:	854a                	mv	a0,s2
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	980080e7          	jalr	-1664(ra) # 80002f86 <brelse>
}
    8000360e:	60e2                	ld	ra,24(sp)
    80003610:	6442                	ld	s0,16(sp)
    80003612:	64a2                	ld	s1,8(sp)
    80003614:	6902                	ld	s2,0(sp)
    80003616:	6105                	addi	sp,sp,32
    80003618:	8082                	ret

000000008000361a <idup>:
{
    8000361a:	1101                	addi	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	e426                	sd	s1,8(sp)
    80003622:	1000                	addi	s0,sp,32
    80003624:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003626:	0001c517          	auipc	a0,0x1c
    8000362a:	1a250513          	addi	a0,a0,418 # 8001f7c8 <itable>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	5a8080e7          	jalr	1448(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003636:	449c                	lw	a5,8(s1)
    80003638:	2785                	addiw	a5,a5,1
    8000363a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000363c:	0001c517          	auipc	a0,0x1c
    80003640:	18c50513          	addi	a0,a0,396 # 8001f7c8 <itable>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	646080e7          	jalr	1606(ra) # 80000c8a <release>
}
    8000364c:	8526                	mv	a0,s1
    8000364e:	60e2                	ld	ra,24(sp)
    80003650:	6442                	ld	s0,16(sp)
    80003652:	64a2                	ld	s1,8(sp)
    80003654:	6105                	addi	sp,sp,32
    80003656:	8082                	ret

0000000080003658 <ilock>:
{
    80003658:	1101                	addi	sp,sp,-32
    8000365a:	ec06                	sd	ra,24(sp)
    8000365c:	e822                	sd	s0,16(sp)
    8000365e:	e426                	sd	s1,8(sp)
    80003660:	e04a                	sd	s2,0(sp)
    80003662:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003664:	c115                	beqz	a0,80003688 <ilock+0x30>
    80003666:	84aa                	mv	s1,a0
    80003668:	451c                	lw	a5,8(a0)
    8000366a:	00f05f63          	blez	a5,80003688 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000366e:	0541                	addi	a0,a0,16
    80003670:	00001097          	auipc	ra,0x1
    80003674:	cb2080e7          	jalr	-846(ra) # 80004322 <acquiresleep>
  if(ip->valid == 0){
    80003678:	40bc                	lw	a5,64(s1)
    8000367a:	cf99                	beqz	a5,80003698 <ilock+0x40>
}
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6902                	ld	s2,0(sp)
    80003684:	6105                	addi	sp,sp,32
    80003686:	8082                	ret
    panic("ilock");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	f3850513          	addi	a0,a0,-200 # 800085c0 <syscalls+0x190>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	ea0080e7          	jalr	-352(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003698:	40dc                	lw	a5,4(s1)
    8000369a:	0047d79b          	srliw	a5,a5,0x4
    8000369e:	0001c597          	auipc	a1,0x1c
    800036a2:	1225a583          	lw	a1,290(a1) # 8001f7c0 <sb+0x18>
    800036a6:	9dbd                	addw	a1,a1,a5
    800036a8:	4088                	lw	a0,0(s1)
    800036aa:	fffff097          	auipc	ra,0xfffff
    800036ae:	7ac080e7          	jalr	1964(ra) # 80002e56 <bread>
    800036b2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b4:	05850593          	addi	a1,a0,88
    800036b8:	40dc                	lw	a5,4(s1)
    800036ba:	8bbd                	andi	a5,a5,15
    800036bc:	079a                	slli	a5,a5,0x6
    800036be:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036c0:	00059783          	lh	a5,0(a1)
    800036c4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036c8:	00259783          	lh	a5,2(a1)
    800036cc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036d0:	00459783          	lh	a5,4(a1)
    800036d4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036d8:	00659783          	lh	a5,6(a1)
    800036dc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036e0:	459c                	lw	a5,8(a1)
    800036e2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036e4:	03400613          	li	a2,52
    800036e8:	05b1                	addi	a1,a1,12
    800036ea:	05048513          	addi	a0,s1,80
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	644080e7          	jalr	1604(ra) # 80000d32 <memmove>
    brelse(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	88e080e7          	jalr	-1906(ra) # 80002f86 <brelse>
    ip->valid = 1;
    80003700:	4785                	li	a5,1
    80003702:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003704:	04449783          	lh	a5,68(s1)
    80003708:	fbb5                	bnez	a5,8000367c <ilock+0x24>
      panic("ilock: no type");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	ebe50513          	addi	a0,a0,-322 # 800085c8 <syscalls+0x198>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e1e080e7          	jalr	-482(ra) # 80000530 <panic>

000000008000371a <iunlock>:
{
    8000371a:	1101                	addi	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	e04a                	sd	s2,0(sp)
    80003724:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003726:	c905                	beqz	a0,80003756 <iunlock+0x3c>
    80003728:	84aa                	mv	s1,a0
    8000372a:	01050913          	addi	s2,a0,16
    8000372e:	854a                	mv	a0,s2
    80003730:	00001097          	auipc	ra,0x1
    80003734:	c8c080e7          	jalr	-884(ra) # 800043bc <holdingsleep>
    80003738:	cd19                	beqz	a0,80003756 <iunlock+0x3c>
    8000373a:	449c                	lw	a5,8(s1)
    8000373c:	00f05d63          	blez	a5,80003756 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003740:	854a                	mv	a0,s2
    80003742:	00001097          	auipc	ra,0x1
    80003746:	c36080e7          	jalr	-970(ra) # 80004378 <releasesleep>
}
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6902                	ld	s2,0(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret
    panic("iunlock");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	e8250513          	addi	a0,a0,-382 # 800085d8 <syscalls+0x1a8>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	dd2080e7          	jalr	-558(ra) # 80000530 <panic>

0000000080003766 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003766:	7179                	addi	sp,sp,-48
    80003768:	f406                	sd	ra,40(sp)
    8000376a:	f022                	sd	s0,32(sp)
    8000376c:	ec26                	sd	s1,24(sp)
    8000376e:	e84a                	sd	s2,16(sp)
    80003770:	e44e                	sd	s3,8(sp)
    80003772:	e052                	sd	s4,0(sp)
    80003774:	1800                	addi	s0,sp,48
    80003776:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003778:	05050493          	addi	s1,a0,80
    8000377c:	08050913          	addi	s2,a0,128
    80003780:	a021                	j	80003788 <itrunc+0x22>
    80003782:	0491                	addi	s1,s1,4
    80003784:	01248d63          	beq	s1,s2,8000379e <itrunc+0x38>
    if(ip->addrs[i]){
    80003788:	408c                	lw	a1,0(s1)
    8000378a:	dde5                	beqz	a1,80003782 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000378c:	0009a503          	lw	a0,0(s3)
    80003790:	00000097          	auipc	ra,0x0
    80003794:	90c080e7          	jalr	-1780(ra) # 8000309c <bfree>
      ip->addrs[i] = 0;
    80003798:	0004a023          	sw	zero,0(s1)
    8000379c:	b7dd                	j	80003782 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000379e:	0809a583          	lw	a1,128(s3)
    800037a2:	e185                	bnez	a1,800037c2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037a4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037a8:	854e                	mv	a0,s3
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	de4080e7          	jalr	-540(ra) # 8000358e <iupdate>
}
    800037b2:	70a2                	ld	ra,40(sp)
    800037b4:	7402                	ld	s0,32(sp)
    800037b6:	64e2                	ld	s1,24(sp)
    800037b8:	6942                	ld	s2,16(sp)
    800037ba:	69a2                	ld	s3,8(sp)
    800037bc:	6a02                	ld	s4,0(sp)
    800037be:	6145                	addi	sp,sp,48
    800037c0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037c2:	0009a503          	lw	a0,0(s3)
    800037c6:	fffff097          	auipc	ra,0xfffff
    800037ca:	690080e7          	jalr	1680(ra) # 80002e56 <bread>
    800037ce:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037d0:	05850493          	addi	s1,a0,88
    800037d4:	45850913          	addi	s2,a0,1112
    800037d8:	a811                	j	800037ec <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037da:	0009a503          	lw	a0,0(s3)
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	8be080e7          	jalr	-1858(ra) # 8000309c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037e6:	0491                	addi	s1,s1,4
    800037e8:	01248563          	beq	s1,s2,800037f2 <itrunc+0x8c>
      if(a[j])
    800037ec:	408c                	lw	a1,0(s1)
    800037ee:	dde5                	beqz	a1,800037e6 <itrunc+0x80>
    800037f0:	b7ed                	j	800037da <itrunc+0x74>
    brelse(bp);
    800037f2:	8552                	mv	a0,s4
    800037f4:	fffff097          	auipc	ra,0xfffff
    800037f8:	792080e7          	jalr	1938(ra) # 80002f86 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037fc:	0809a583          	lw	a1,128(s3)
    80003800:	0009a503          	lw	a0,0(s3)
    80003804:	00000097          	auipc	ra,0x0
    80003808:	898080e7          	jalr	-1896(ra) # 8000309c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000380c:	0809a023          	sw	zero,128(s3)
    80003810:	bf51                	j	800037a4 <itrunc+0x3e>

0000000080003812 <iput>:
{
    80003812:	1101                	addi	sp,sp,-32
    80003814:	ec06                	sd	ra,24(sp)
    80003816:	e822                	sd	s0,16(sp)
    80003818:	e426                	sd	s1,8(sp)
    8000381a:	e04a                	sd	s2,0(sp)
    8000381c:	1000                	addi	s0,sp,32
    8000381e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003820:	0001c517          	auipc	a0,0x1c
    80003824:	fa850513          	addi	a0,a0,-88 # 8001f7c8 <itable>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	3ae080e7          	jalr	942(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003830:	4498                	lw	a4,8(s1)
    80003832:	4785                	li	a5,1
    80003834:	02f70363          	beq	a4,a5,8000385a <iput+0x48>
  ip->ref--;
    80003838:	449c                	lw	a5,8(s1)
    8000383a:	37fd                	addiw	a5,a5,-1
    8000383c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000383e:	0001c517          	auipc	a0,0x1c
    80003842:	f8a50513          	addi	a0,a0,-118 # 8001f7c8 <itable>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	444080e7          	jalr	1092(ra) # 80000c8a <release>
}
    8000384e:	60e2                	ld	ra,24(sp)
    80003850:	6442                	ld	s0,16(sp)
    80003852:	64a2                	ld	s1,8(sp)
    80003854:	6902                	ld	s2,0(sp)
    80003856:	6105                	addi	sp,sp,32
    80003858:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000385a:	40bc                	lw	a5,64(s1)
    8000385c:	dff1                	beqz	a5,80003838 <iput+0x26>
    8000385e:	04a49783          	lh	a5,74(s1)
    80003862:	fbf9                	bnez	a5,80003838 <iput+0x26>
    acquiresleep(&ip->lock);
    80003864:	01048913          	addi	s2,s1,16
    80003868:	854a                	mv	a0,s2
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	ab8080e7          	jalr	-1352(ra) # 80004322 <acquiresleep>
    release(&itable.lock);
    80003872:	0001c517          	auipc	a0,0x1c
    80003876:	f5650513          	addi	a0,a0,-170 # 8001f7c8 <itable>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	410080e7          	jalr	1040(ra) # 80000c8a <release>
    itrunc(ip);
    80003882:	8526                	mv	a0,s1
    80003884:	00000097          	auipc	ra,0x0
    80003888:	ee2080e7          	jalr	-286(ra) # 80003766 <itrunc>
    ip->type = 0;
    8000388c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003890:	8526                	mv	a0,s1
    80003892:	00000097          	auipc	ra,0x0
    80003896:	cfc080e7          	jalr	-772(ra) # 8000358e <iupdate>
    ip->valid = 0;
    8000389a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	ad8080e7          	jalr	-1320(ra) # 80004378 <releasesleep>
    acquire(&itable.lock);
    800038a8:	0001c517          	auipc	a0,0x1c
    800038ac:	f2050513          	addi	a0,a0,-224 # 8001f7c8 <itable>
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	326080e7          	jalr	806(ra) # 80000bd6 <acquire>
    800038b8:	b741                	j	80003838 <iput+0x26>

00000000800038ba <iunlockput>:
{
    800038ba:	1101                	addi	sp,sp,-32
    800038bc:	ec06                	sd	ra,24(sp)
    800038be:	e822                	sd	s0,16(sp)
    800038c0:	e426                	sd	s1,8(sp)
    800038c2:	1000                	addi	s0,sp,32
    800038c4:	84aa                	mv	s1,a0
  iunlock(ip);
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	e54080e7          	jalr	-428(ra) # 8000371a <iunlock>
  iput(ip);
    800038ce:	8526                	mv	a0,s1
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	f42080e7          	jalr	-190(ra) # 80003812 <iput>
}
    800038d8:	60e2                	ld	ra,24(sp)
    800038da:	6442                	ld	s0,16(sp)
    800038dc:	64a2                	ld	s1,8(sp)
    800038de:	6105                	addi	sp,sp,32
    800038e0:	8082                	ret

00000000800038e2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038e2:	1141                	addi	sp,sp,-16
    800038e4:	e422                	sd	s0,8(sp)
    800038e6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038e8:	411c                	lw	a5,0(a0)
    800038ea:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038ec:	415c                	lw	a5,4(a0)
    800038ee:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038f0:	04451783          	lh	a5,68(a0)
    800038f4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038f8:	04a51783          	lh	a5,74(a0)
    800038fc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003900:	04c56783          	lwu	a5,76(a0)
    80003904:	e99c                	sd	a5,16(a1)
}
    80003906:	6422                	ld	s0,8(sp)
    80003908:	0141                	addi	sp,sp,16
    8000390a:	8082                	ret

000000008000390c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000390c:	457c                	lw	a5,76(a0)
    8000390e:	0ed7e963          	bltu	a5,a3,80003a00 <readi+0xf4>
{
    80003912:	7159                	addi	sp,sp,-112
    80003914:	f486                	sd	ra,104(sp)
    80003916:	f0a2                	sd	s0,96(sp)
    80003918:	eca6                	sd	s1,88(sp)
    8000391a:	e8ca                	sd	s2,80(sp)
    8000391c:	e4ce                	sd	s3,72(sp)
    8000391e:	e0d2                	sd	s4,64(sp)
    80003920:	fc56                	sd	s5,56(sp)
    80003922:	f85a                	sd	s6,48(sp)
    80003924:	f45e                	sd	s7,40(sp)
    80003926:	f062                	sd	s8,32(sp)
    80003928:	ec66                	sd	s9,24(sp)
    8000392a:	e86a                	sd	s10,16(sp)
    8000392c:	e46e                	sd	s11,8(sp)
    8000392e:	1880                	addi	s0,sp,112
    80003930:	8baa                	mv	s7,a0
    80003932:	8c2e                	mv	s8,a1
    80003934:	8ab2                	mv	s5,a2
    80003936:	84b6                	mv	s1,a3
    80003938:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000393a:	9f35                	addw	a4,a4,a3
    return 0;
    8000393c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000393e:	0ad76063          	bltu	a4,a3,800039de <readi+0xd2>
  if(off + n > ip->size)
    80003942:	00e7f463          	bgeu	a5,a4,8000394a <readi+0x3e>
    n = ip->size - off;
    80003946:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000394a:	0a0b0963          	beqz	s6,800039fc <readi+0xf0>
    8000394e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003950:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003954:	5cfd                	li	s9,-1
    80003956:	a82d                	j	80003990 <readi+0x84>
    80003958:	020a1d93          	slli	s11,s4,0x20
    8000395c:	020ddd93          	srli	s11,s11,0x20
    80003960:	05890613          	addi	a2,s2,88
    80003964:	86ee                	mv	a3,s11
    80003966:	963a                	add	a2,a2,a4
    80003968:	85d6                	mv	a1,s5
    8000396a:	8562                	mv	a0,s8
    8000396c:	fffff097          	auipc	ra,0xfffff
    80003970:	a90080e7          	jalr	-1392(ra) # 800023fc <either_copyout>
    80003974:	05950d63          	beq	a0,s9,800039ce <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003978:	854a                	mv	a0,s2
    8000397a:	fffff097          	auipc	ra,0xfffff
    8000397e:	60c080e7          	jalr	1548(ra) # 80002f86 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003982:	013a09bb          	addw	s3,s4,s3
    80003986:	009a04bb          	addw	s1,s4,s1
    8000398a:	9aee                	add	s5,s5,s11
    8000398c:	0569f763          	bgeu	s3,s6,800039da <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003990:	000ba903          	lw	s2,0(s7)
    80003994:	00a4d59b          	srliw	a1,s1,0xa
    80003998:	855e                	mv	a0,s7
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	8b0080e7          	jalr	-1872(ra) # 8000324a <bmap>
    800039a2:	0005059b          	sext.w	a1,a0
    800039a6:	854a                	mv	a0,s2
    800039a8:	fffff097          	auipc	ra,0xfffff
    800039ac:	4ae080e7          	jalr	1198(ra) # 80002e56 <bread>
    800039b0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039b2:	3ff4f713          	andi	a4,s1,1023
    800039b6:	40ed07bb          	subw	a5,s10,a4
    800039ba:	413b06bb          	subw	a3,s6,s3
    800039be:	8a3e                	mv	s4,a5
    800039c0:	2781                	sext.w	a5,a5
    800039c2:	0006861b          	sext.w	a2,a3
    800039c6:	f8f679e3          	bgeu	a2,a5,80003958 <readi+0x4c>
    800039ca:	8a36                	mv	s4,a3
    800039cc:	b771                	j	80003958 <readi+0x4c>
      brelse(bp);
    800039ce:	854a                	mv	a0,s2
    800039d0:	fffff097          	auipc	ra,0xfffff
    800039d4:	5b6080e7          	jalr	1462(ra) # 80002f86 <brelse>
      tot = -1;
    800039d8:	59fd                	li	s3,-1
  }
  return tot;
    800039da:	0009851b          	sext.w	a0,s3
}
    800039de:	70a6                	ld	ra,104(sp)
    800039e0:	7406                	ld	s0,96(sp)
    800039e2:	64e6                	ld	s1,88(sp)
    800039e4:	6946                	ld	s2,80(sp)
    800039e6:	69a6                	ld	s3,72(sp)
    800039e8:	6a06                	ld	s4,64(sp)
    800039ea:	7ae2                	ld	s5,56(sp)
    800039ec:	7b42                	ld	s6,48(sp)
    800039ee:	7ba2                	ld	s7,40(sp)
    800039f0:	7c02                	ld	s8,32(sp)
    800039f2:	6ce2                	ld	s9,24(sp)
    800039f4:	6d42                	ld	s10,16(sp)
    800039f6:	6da2                	ld	s11,8(sp)
    800039f8:	6165                	addi	sp,sp,112
    800039fa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039fc:	89da                	mv	s3,s6
    800039fe:	bff1                	j	800039da <readi+0xce>
    return 0;
    80003a00:	4501                	li	a0,0
}
    80003a02:	8082                	ret

0000000080003a04 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a04:	457c                	lw	a5,76(a0)
    80003a06:	10d7e863          	bltu	a5,a3,80003b16 <writei+0x112>
{
    80003a0a:	7159                	addi	sp,sp,-112
    80003a0c:	f486                	sd	ra,104(sp)
    80003a0e:	f0a2                	sd	s0,96(sp)
    80003a10:	eca6                	sd	s1,88(sp)
    80003a12:	e8ca                	sd	s2,80(sp)
    80003a14:	e4ce                	sd	s3,72(sp)
    80003a16:	e0d2                	sd	s4,64(sp)
    80003a18:	fc56                	sd	s5,56(sp)
    80003a1a:	f85a                	sd	s6,48(sp)
    80003a1c:	f45e                	sd	s7,40(sp)
    80003a1e:	f062                	sd	s8,32(sp)
    80003a20:	ec66                	sd	s9,24(sp)
    80003a22:	e86a                	sd	s10,16(sp)
    80003a24:	e46e                	sd	s11,8(sp)
    80003a26:	1880                	addi	s0,sp,112
    80003a28:	8b2a                	mv	s6,a0
    80003a2a:	8c2e                	mv	s8,a1
    80003a2c:	8ab2                	mv	s5,a2
    80003a2e:	8936                	mv	s2,a3
    80003a30:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a32:	00e687bb          	addw	a5,a3,a4
    80003a36:	0ed7e263          	bltu	a5,a3,80003b1a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a3a:	00043737          	lui	a4,0x43
    80003a3e:	0ef76063          	bltu	a4,a5,80003b1e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a42:	0c0b8863          	beqz	s7,80003b12 <writei+0x10e>
    80003a46:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a48:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a4c:	5cfd                	li	s9,-1
    80003a4e:	a091                	j	80003a92 <writei+0x8e>
    80003a50:	02099d93          	slli	s11,s3,0x20
    80003a54:	020ddd93          	srli	s11,s11,0x20
    80003a58:	05848513          	addi	a0,s1,88
    80003a5c:	86ee                	mv	a3,s11
    80003a5e:	8656                	mv	a2,s5
    80003a60:	85e2                	mv	a1,s8
    80003a62:	953a                	add	a0,a0,a4
    80003a64:	fffff097          	auipc	ra,0xfffff
    80003a68:	9ee080e7          	jalr	-1554(ra) # 80002452 <either_copyin>
    80003a6c:	07950263          	beq	a0,s9,80003ad0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a70:	8526                	mv	a0,s1
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	790080e7          	jalr	1936(ra) # 80004202 <log_write>
    brelse(bp);
    80003a7a:	8526                	mv	a0,s1
    80003a7c:	fffff097          	auipc	ra,0xfffff
    80003a80:	50a080e7          	jalr	1290(ra) # 80002f86 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a84:	01498a3b          	addw	s4,s3,s4
    80003a88:	0129893b          	addw	s2,s3,s2
    80003a8c:	9aee                	add	s5,s5,s11
    80003a8e:	057a7663          	bgeu	s4,s7,80003ada <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a92:	000b2483          	lw	s1,0(s6)
    80003a96:	00a9559b          	srliw	a1,s2,0xa
    80003a9a:	855a                	mv	a0,s6
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	7ae080e7          	jalr	1966(ra) # 8000324a <bmap>
    80003aa4:	0005059b          	sext.w	a1,a0
    80003aa8:	8526                	mv	a0,s1
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	3ac080e7          	jalr	940(ra) # 80002e56 <bread>
    80003ab2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab4:	3ff97713          	andi	a4,s2,1023
    80003ab8:	40ed07bb          	subw	a5,s10,a4
    80003abc:	414b86bb          	subw	a3,s7,s4
    80003ac0:	89be                	mv	s3,a5
    80003ac2:	2781                	sext.w	a5,a5
    80003ac4:	0006861b          	sext.w	a2,a3
    80003ac8:	f8f674e3          	bgeu	a2,a5,80003a50 <writei+0x4c>
    80003acc:	89b6                	mv	s3,a3
    80003ace:	b749                	j	80003a50 <writei+0x4c>
      brelse(bp);
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	4b4080e7          	jalr	1204(ra) # 80002f86 <brelse>
  }

  if(off > ip->size)
    80003ada:	04cb2783          	lw	a5,76(s6)
    80003ade:	0127f463          	bgeu	a5,s2,80003ae6 <writei+0xe2>
    ip->size = off;
    80003ae2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ae6:	855a                	mv	a0,s6
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	aa6080e7          	jalr	-1370(ra) # 8000358e <iupdate>

  return tot;
    80003af0:	000a051b          	sext.w	a0,s4
}
    80003af4:	70a6                	ld	ra,104(sp)
    80003af6:	7406                	ld	s0,96(sp)
    80003af8:	64e6                	ld	s1,88(sp)
    80003afa:	6946                	ld	s2,80(sp)
    80003afc:	69a6                	ld	s3,72(sp)
    80003afe:	6a06                	ld	s4,64(sp)
    80003b00:	7ae2                	ld	s5,56(sp)
    80003b02:	7b42                	ld	s6,48(sp)
    80003b04:	7ba2                	ld	s7,40(sp)
    80003b06:	7c02                	ld	s8,32(sp)
    80003b08:	6ce2                	ld	s9,24(sp)
    80003b0a:	6d42                	ld	s10,16(sp)
    80003b0c:	6da2                	ld	s11,8(sp)
    80003b0e:	6165                	addi	sp,sp,112
    80003b10:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b12:	8a5e                	mv	s4,s7
    80003b14:	bfc9                	j	80003ae6 <writei+0xe2>
    return -1;
    80003b16:	557d                	li	a0,-1
}
    80003b18:	8082                	ret
    return -1;
    80003b1a:	557d                	li	a0,-1
    80003b1c:	bfe1                	j	80003af4 <writei+0xf0>
    return -1;
    80003b1e:	557d                	li	a0,-1
    80003b20:	bfd1                	j	80003af4 <writei+0xf0>

0000000080003b22 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b22:	1141                	addi	sp,sp,-16
    80003b24:	e406                	sd	ra,8(sp)
    80003b26:	e022                	sd	s0,0(sp)
    80003b28:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b2a:	4639                	li	a2,14
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	282080e7          	jalr	642(ra) # 80000dae <strncmp>
}
    80003b34:	60a2                	ld	ra,8(sp)
    80003b36:	6402                	ld	s0,0(sp)
    80003b38:	0141                	addi	sp,sp,16
    80003b3a:	8082                	ret

0000000080003b3c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b3c:	7139                	addi	sp,sp,-64
    80003b3e:	fc06                	sd	ra,56(sp)
    80003b40:	f822                	sd	s0,48(sp)
    80003b42:	f426                	sd	s1,40(sp)
    80003b44:	f04a                	sd	s2,32(sp)
    80003b46:	ec4e                	sd	s3,24(sp)
    80003b48:	e852                	sd	s4,16(sp)
    80003b4a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b4c:	04451703          	lh	a4,68(a0)
    80003b50:	4785                	li	a5,1
    80003b52:	00f71a63          	bne	a4,a5,80003b66 <dirlookup+0x2a>
    80003b56:	892a                	mv	s2,a0
    80003b58:	89ae                	mv	s3,a1
    80003b5a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b5c:	457c                	lw	a5,76(a0)
    80003b5e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b60:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b62:	e79d                	bnez	a5,80003b90 <dirlookup+0x54>
    80003b64:	a8a5                	j	80003bdc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b66:	00005517          	auipc	a0,0x5
    80003b6a:	a7a50513          	addi	a0,a0,-1414 # 800085e0 <syscalls+0x1b0>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	9c2080e7          	jalr	-1598(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003b76:	00005517          	auipc	a0,0x5
    80003b7a:	a8250513          	addi	a0,a0,-1406 # 800085f8 <syscalls+0x1c8>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	9b2080e7          	jalr	-1614(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b86:	24c1                	addiw	s1,s1,16
    80003b88:	04c92783          	lw	a5,76(s2)
    80003b8c:	04f4f763          	bgeu	s1,a5,80003bda <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b90:	4741                	li	a4,16
    80003b92:	86a6                	mv	a3,s1
    80003b94:	fc040613          	addi	a2,s0,-64
    80003b98:	4581                	li	a1,0
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	d70080e7          	jalr	-656(ra) # 8000390c <readi>
    80003ba4:	47c1                	li	a5,16
    80003ba6:	fcf518e3          	bne	a0,a5,80003b76 <dirlookup+0x3a>
    if(de.inum == 0)
    80003baa:	fc045783          	lhu	a5,-64(s0)
    80003bae:	dfe1                	beqz	a5,80003b86 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bb0:	fc240593          	addi	a1,s0,-62
    80003bb4:	854e                	mv	a0,s3
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	f6c080e7          	jalr	-148(ra) # 80003b22 <namecmp>
    80003bbe:	f561                	bnez	a0,80003b86 <dirlookup+0x4a>
      if(poff)
    80003bc0:	000a0463          	beqz	s4,80003bc8 <dirlookup+0x8c>
        *poff = off;
    80003bc4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bc8:	fc045583          	lhu	a1,-64(s0)
    80003bcc:	00092503          	lw	a0,0(s2)
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	754080e7          	jalr	1876(ra) # 80003324 <iget>
    80003bd8:	a011                	j	80003bdc <dirlookup+0xa0>
  return 0;
    80003bda:	4501                	li	a0,0
}
    80003bdc:	70e2                	ld	ra,56(sp)
    80003bde:	7442                	ld	s0,48(sp)
    80003be0:	74a2                	ld	s1,40(sp)
    80003be2:	7902                	ld	s2,32(sp)
    80003be4:	69e2                	ld	s3,24(sp)
    80003be6:	6a42                	ld	s4,16(sp)
    80003be8:	6121                	addi	sp,sp,64
    80003bea:	8082                	ret

0000000080003bec <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bec:	711d                	addi	sp,sp,-96
    80003bee:	ec86                	sd	ra,88(sp)
    80003bf0:	e8a2                	sd	s0,80(sp)
    80003bf2:	e4a6                	sd	s1,72(sp)
    80003bf4:	e0ca                	sd	s2,64(sp)
    80003bf6:	fc4e                	sd	s3,56(sp)
    80003bf8:	f852                	sd	s4,48(sp)
    80003bfa:	f456                	sd	s5,40(sp)
    80003bfc:	f05a                	sd	s6,32(sp)
    80003bfe:	ec5e                	sd	s7,24(sp)
    80003c00:	e862                	sd	s8,16(sp)
    80003c02:	e466                	sd	s9,8(sp)
    80003c04:	1080                	addi	s0,sp,96
    80003c06:	84aa                	mv	s1,a0
    80003c08:	8b2e                	mv	s6,a1
    80003c0a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c0c:	00054703          	lbu	a4,0(a0)
    80003c10:	02f00793          	li	a5,47
    80003c14:	02f70363          	beq	a4,a5,80003c3a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c18:	ffffe097          	auipc	ra,0xffffe
    80003c1c:	d7c080e7          	jalr	-644(ra) # 80001994 <myproc>
    80003c20:	15053503          	ld	a0,336(a0)
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	9f6080e7          	jalr	-1546(ra) # 8000361a <idup>
    80003c2c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c2e:	02f00913          	li	s2,47
  len = path - s;
    80003c32:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c34:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c36:	4c05                	li	s8,1
    80003c38:	a865                	j	80003cf0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c3a:	4585                	li	a1,1
    80003c3c:	4505                	li	a0,1
    80003c3e:	fffff097          	auipc	ra,0xfffff
    80003c42:	6e6080e7          	jalr	1766(ra) # 80003324 <iget>
    80003c46:	89aa                	mv	s3,a0
    80003c48:	b7dd                	j	80003c2e <namex+0x42>
      iunlockput(ip);
    80003c4a:	854e                	mv	a0,s3
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	c6e080e7          	jalr	-914(ra) # 800038ba <iunlockput>
      return 0;
    80003c54:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c56:	854e                	mv	a0,s3
    80003c58:	60e6                	ld	ra,88(sp)
    80003c5a:	6446                	ld	s0,80(sp)
    80003c5c:	64a6                	ld	s1,72(sp)
    80003c5e:	6906                	ld	s2,64(sp)
    80003c60:	79e2                	ld	s3,56(sp)
    80003c62:	7a42                	ld	s4,48(sp)
    80003c64:	7aa2                	ld	s5,40(sp)
    80003c66:	7b02                	ld	s6,32(sp)
    80003c68:	6be2                	ld	s7,24(sp)
    80003c6a:	6c42                	ld	s8,16(sp)
    80003c6c:	6ca2                	ld	s9,8(sp)
    80003c6e:	6125                	addi	sp,sp,96
    80003c70:	8082                	ret
      iunlock(ip);
    80003c72:	854e                	mv	a0,s3
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	aa6080e7          	jalr	-1370(ra) # 8000371a <iunlock>
      return ip;
    80003c7c:	bfe9                	j	80003c56 <namex+0x6a>
      iunlockput(ip);
    80003c7e:	854e                	mv	a0,s3
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	c3a080e7          	jalr	-966(ra) # 800038ba <iunlockput>
      return 0;
    80003c88:	89d2                	mv	s3,s4
    80003c8a:	b7f1                	j	80003c56 <namex+0x6a>
  len = path - s;
    80003c8c:	40b48633          	sub	a2,s1,a1
    80003c90:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c94:	094cd463          	bge	s9,s4,80003d1c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c98:	4639                	li	a2,14
    80003c9a:	8556                	mv	a0,s5
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	096080e7          	jalr	150(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003ca4:	0004c783          	lbu	a5,0(s1)
    80003ca8:	01279763          	bne	a5,s2,80003cb6 <namex+0xca>
    path++;
    80003cac:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cae:	0004c783          	lbu	a5,0(s1)
    80003cb2:	ff278de3          	beq	a5,s2,80003cac <namex+0xc0>
    ilock(ip);
    80003cb6:	854e                	mv	a0,s3
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	9a0080e7          	jalr	-1632(ra) # 80003658 <ilock>
    if(ip->type != T_DIR){
    80003cc0:	04499783          	lh	a5,68(s3)
    80003cc4:	f98793e3          	bne	a5,s8,80003c4a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cc8:	000b0563          	beqz	s6,80003cd2 <namex+0xe6>
    80003ccc:	0004c783          	lbu	a5,0(s1)
    80003cd0:	d3cd                	beqz	a5,80003c72 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cd2:	865e                	mv	a2,s7
    80003cd4:	85d6                	mv	a1,s5
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	e64080e7          	jalr	-412(ra) # 80003b3c <dirlookup>
    80003ce0:	8a2a                	mv	s4,a0
    80003ce2:	dd51                	beqz	a0,80003c7e <namex+0x92>
    iunlockput(ip);
    80003ce4:	854e                	mv	a0,s3
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	bd4080e7          	jalr	-1068(ra) # 800038ba <iunlockput>
    ip = next;
    80003cee:	89d2                	mv	s3,s4
  while(*path == '/')
    80003cf0:	0004c783          	lbu	a5,0(s1)
    80003cf4:	05279763          	bne	a5,s2,80003d42 <namex+0x156>
    path++;
    80003cf8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cfa:	0004c783          	lbu	a5,0(s1)
    80003cfe:	ff278de3          	beq	a5,s2,80003cf8 <namex+0x10c>
  if(*path == 0)
    80003d02:	c79d                	beqz	a5,80003d30 <namex+0x144>
    path++;
    80003d04:	85a6                	mv	a1,s1
  len = path - s;
    80003d06:	8a5e                	mv	s4,s7
    80003d08:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0a:	01278963          	beq	a5,s2,80003d1c <namex+0x130>
    80003d0e:	dfbd                	beqz	a5,80003c8c <namex+0xa0>
    path++;
    80003d10:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d12:	0004c783          	lbu	a5,0(s1)
    80003d16:	ff279ce3          	bne	a5,s2,80003d0e <namex+0x122>
    80003d1a:	bf8d                	j	80003c8c <namex+0xa0>
    memmove(name, s, len);
    80003d1c:	2601                	sext.w	a2,a2
    80003d1e:	8556                	mv	a0,s5
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	012080e7          	jalr	18(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003d28:	9a56                	add	s4,s4,s5
    80003d2a:	000a0023          	sb	zero,0(s4)
    80003d2e:	bf9d                	j	80003ca4 <namex+0xb8>
  if(nameiparent){
    80003d30:	f20b03e3          	beqz	s6,80003c56 <namex+0x6a>
    iput(ip);
    80003d34:	854e                	mv	a0,s3
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	adc080e7          	jalr	-1316(ra) # 80003812 <iput>
    return 0;
    80003d3e:	4981                	li	s3,0
    80003d40:	bf19                	j	80003c56 <namex+0x6a>
  if(*path == 0)
    80003d42:	d7fd                	beqz	a5,80003d30 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d44:	0004c783          	lbu	a5,0(s1)
    80003d48:	85a6                	mv	a1,s1
    80003d4a:	b7d1                	j	80003d0e <namex+0x122>

0000000080003d4c <dirlink>:
{
    80003d4c:	7139                	addi	sp,sp,-64
    80003d4e:	fc06                	sd	ra,56(sp)
    80003d50:	f822                	sd	s0,48(sp)
    80003d52:	f426                	sd	s1,40(sp)
    80003d54:	f04a                	sd	s2,32(sp)
    80003d56:	ec4e                	sd	s3,24(sp)
    80003d58:	e852                	sd	s4,16(sp)
    80003d5a:	0080                	addi	s0,sp,64
    80003d5c:	892a                	mv	s2,a0
    80003d5e:	8a2e                	mv	s4,a1
    80003d60:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d62:	4601                	li	a2,0
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	dd8080e7          	jalr	-552(ra) # 80003b3c <dirlookup>
    80003d6c:	e93d                	bnez	a0,80003de2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6e:	04c92483          	lw	s1,76(s2)
    80003d72:	c49d                	beqz	s1,80003da0 <dirlink+0x54>
    80003d74:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d76:	4741                	li	a4,16
    80003d78:	86a6                	mv	a3,s1
    80003d7a:	fc040613          	addi	a2,s0,-64
    80003d7e:	4581                	li	a1,0
    80003d80:	854a                	mv	a0,s2
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	b8a080e7          	jalr	-1142(ra) # 8000390c <readi>
    80003d8a:	47c1                	li	a5,16
    80003d8c:	06f51163          	bne	a0,a5,80003dee <dirlink+0xa2>
    if(de.inum == 0)
    80003d90:	fc045783          	lhu	a5,-64(s0)
    80003d94:	c791                	beqz	a5,80003da0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d96:	24c1                	addiw	s1,s1,16
    80003d98:	04c92783          	lw	a5,76(s2)
    80003d9c:	fcf4ede3          	bltu	s1,a5,80003d76 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003da0:	4639                	li	a2,14
    80003da2:	85d2                	mv	a1,s4
    80003da4:	fc240513          	addi	a0,s0,-62
    80003da8:	ffffd097          	auipc	ra,0xffffd
    80003dac:	042080e7          	jalr	66(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003db0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db4:	4741                	li	a4,16
    80003db6:	86a6                	mv	a3,s1
    80003db8:	fc040613          	addi	a2,s0,-64
    80003dbc:	4581                	li	a1,0
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	c44080e7          	jalr	-956(ra) # 80003a04 <writei>
    80003dc8:	872a                	mv	a4,a0
    80003dca:	47c1                	li	a5,16
  return 0;
    80003dcc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dce:	02f71863          	bne	a4,a5,80003dfe <dirlink+0xb2>
}
    80003dd2:	70e2                	ld	ra,56(sp)
    80003dd4:	7442                	ld	s0,48(sp)
    80003dd6:	74a2                	ld	s1,40(sp)
    80003dd8:	7902                	ld	s2,32(sp)
    80003dda:	69e2                	ld	s3,24(sp)
    80003ddc:	6a42                	ld	s4,16(sp)
    80003dde:	6121                	addi	sp,sp,64
    80003de0:	8082                	ret
    iput(ip);
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	a30080e7          	jalr	-1488(ra) # 80003812 <iput>
    return -1;
    80003dea:	557d                	li	a0,-1
    80003dec:	b7dd                	j	80003dd2 <dirlink+0x86>
      panic("dirlink read");
    80003dee:	00005517          	auipc	a0,0x5
    80003df2:	81a50513          	addi	a0,a0,-2022 # 80008608 <syscalls+0x1d8>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	73a080e7          	jalr	1850(ra) # 80000530 <panic>
    panic("dirlink");
    80003dfe:	00005517          	auipc	a0,0x5
    80003e02:	91a50513          	addi	a0,a0,-1766 # 80008718 <syscalls+0x2e8>
    80003e06:	ffffc097          	auipc	ra,0xffffc
    80003e0a:	72a080e7          	jalr	1834(ra) # 80000530 <panic>

0000000080003e0e <namei>:

struct inode*
namei(char *path)
{
    80003e0e:	1101                	addi	sp,sp,-32
    80003e10:	ec06                	sd	ra,24(sp)
    80003e12:	e822                	sd	s0,16(sp)
    80003e14:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e16:	fe040613          	addi	a2,s0,-32
    80003e1a:	4581                	li	a1,0
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	dd0080e7          	jalr	-560(ra) # 80003bec <namex>
}
    80003e24:	60e2                	ld	ra,24(sp)
    80003e26:	6442                	ld	s0,16(sp)
    80003e28:	6105                	addi	sp,sp,32
    80003e2a:	8082                	ret

0000000080003e2c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e2c:	1141                	addi	sp,sp,-16
    80003e2e:	e406                	sd	ra,8(sp)
    80003e30:	e022                	sd	s0,0(sp)
    80003e32:	0800                	addi	s0,sp,16
    80003e34:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e36:	4585                	li	a1,1
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	db4080e7          	jalr	-588(ra) # 80003bec <namex>
}
    80003e40:	60a2                	ld	ra,8(sp)
    80003e42:	6402                	ld	s0,0(sp)
    80003e44:	0141                	addi	sp,sp,16
    80003e46:	8082                	ret

0000000080003e48 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e48:	1101                	addi	sp,sp,-32
    80003e4a:	ec06                	sd	ra,24(sp)
    80003e4c:	e822                	sd	s0,16(sp)
    80003e4e:	e426                	sd	s1,8(sp)
    80003e50:	e04a                	sd	s2,0(sp)
    80003e52:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e54:	0001d917          	auipc	s2,0x1d
    80003e58:	41c90913          	addi	s2,s2,1052 # 80021270 <log>
    80003e5c:	01892583          	lw	a1,24(s2)
    80003e60:	02892503          	lw	a0,40(s2)
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	ff2080e7          	jalr	-14(ra) # 80002e56 <bread>
    80003e6c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e6e:	02c92683          	lw	a3,44(s2)
    80003e72:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e74:	02d05763          	blez	a3,80003ea2 <write_head+0x5a>
    80003e78:	0001d797          	auipc	a5,0x1d
    80003e7c:	42878793          	addi	a5,a5,1064 # 800212a0 <log+0x30>
    80003e80:	05c50713          	addi	a4,a0,92
    80003e84:	36fd                	addiw	a3,a3,-1
    80003e86:	1682                	slli	a3,a3,0x20
    80003e88:	9281                	srli	a3,a3,0x20
    80003e8a:	068a                	slli	a3,a3,0x2
    80003e8c:	0001d617          	auipc	a2,0x1d
    80003e90:	41860613          	addi	a2,a2,1048 # 800212a4 <log+0x34>
    80003e94:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e96:	4390                	lw	a2,0(a5)
    80003e98:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e9a:	0791                	addi	a5,a5,4
    80003e9c:	0711                	addi	a4,a4,4
    80003e9e:	fed79ce3          	bne	a5,a3,80003e96 <write_head+0x4e>
  }
  bwrite(buf);
    80003ea2:	8526                	mv	a0,s1
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	0a4080e7          	jalr	164(ra) # 80002f48 <bwrite>
  brelse(buf);
    80003eac:	8526                	mv	a0,s1
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	0d8080e7          	jalr	216(ra) # 80002f86 <brelse>
}
    80003eb6:	60e2                	ld	ra,24(sp)
    80003eb8:	6442                	ld	s0,16(sp)
    80003eba:	64a2                	ld	s1,8(sp)
    80003ebc:	6902                	ld	s2,0(sp)
    80003ebe:	6105                	addi	sp,sp,32
    80003ec0:	8082                	ret

0000000080003ec2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ec2:	0001d797          	auipc	a5,0x1d
    80003ec6:	3da7a783          	lw	a5,986(a5) # 8002129c <log+0x2c>
    80003eca:	0af05d63          	blez	a5,80003f84 <install_trans+0xc2>
{
    80003ece:	7139                	addi	sp,sp,-64
    80003ed0:	fc06                	sd	ra,56(sp)
    80003ed2:	f822                	sd	s0,48(sp)
    80003ed4:	f426                	sd	s1,40(sp)
    80003ed6:	f04a                	sd	s2,32(sp)
    80003ed8:	ec4e                	sd	s3,24(sp)
    80003eda:	e852                	sd	s4,16(sp)
    80003edc:	e456                	sd	s5,8(sp)
    80003ede:	e05a                	sd	s6,0(sp)
    80003ee0:	0080                	addi	s0,sp,64
    80003ee2:	8b2a                	mv	s6,a0
    80003ee4:	0001da97          	auipc	s5,0x1d
    80003ee8:	3bca8a93          	addi	s5,s5,956 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eec:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eee:	0001d997          	auipc	s3,0x1d
    80003ef2:	38298993          	addi	s3,s3,898 # 80021270 <log>
    80003ef6:	a035                	j	80003f22 <install_trans+0x60>
      bunpin(dbuf);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	166080e7          	jalr	358(ra) # 80003060 <bunpin>
    brelse(lbuf);
    80003f02:	854a                	mv	a0,s2
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	082080e7          	jalr	130(ra) # 80002f86 <brelse>
    brelse(dbuf);
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	078080e7          	jalr	120(ra) # 80002f86 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f16:	2a05                	addiw	s4,s4,1
    80003f18:	0a91                	addi	s5,s5,4
    80003f1a:	02c9a783          	lw	a5,44(s3)
    80003f1e:	04fa5963          	bge	s4,a5,80003f70 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f22:	0189a583          	lw	a1,24(s3)
    80003f26:	014585bb          	addw	a1,a1,s4
    80003f2a:	2585                	addiw	a1,a1,1
    80003f2c:	0289a503          	lw	a0,40(s3)
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	f26080e7          	jalr	-218(ra) # 80002e56 <bread>
    80003f38:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f3a:	000aa583          	lw	a1,0(s5)
    80003f3e:	0289a503          	lw	a0,40(s3)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	f14080e7          	jalr	-236(ra) # 80002e56 <bread>
    80003f4a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f4c:	40000613          	li	a2,1024
    80003f50:	05890593          	addi	a1,s2,88
    80003f54:	05850513          	addi	a0,a0,88
    80003f58:	ffffd097          	auipc	ra,0xffffd
    80003f5c:	dda080e7          	jalr	-550(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f60:	8526                	mv	a0,s1
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	fe6080e7          	jalr	-26(ra) # 80002f48 <bwrite>
    if(recovering == 0)
    80003f6a:	f80b1ce3          	bnez	s6,80003f02 <install_trans+0x40>
    80003f6e:	b769                	j	80003ef8 <install_trans+0x36>
}
    80003f70:	70e2                	ld	ra,56(sp)
    80003f72:	7442                	ld	s0,48(sp)
    80003f74:	74a2                	ld	s1,40(sp)
    80003f76:	7902                	ld	s2,32(sp)
    80003f78:	69e2                	ld	s3,24(sp)
    80003f7a:	6a42                	ld	s4,16(sp)
    80003f7c:	6aa2                	ld	s5,8(sp)
    80003f7e:	6b02                	ld	s6,0(sp)
    80003f80:	6121                	addi	sp,sp,64
    80003f82:	8082                	ret
    80003f84:	8082                	ret

0000000080003f86 <initlog>:
{
    80003f86:	7179                	addi	sp,sp,-48
    80003f88:	f406                	sd	ra,40(sp)
    80003f8a:	f022                	sd	s0,32(sp)
    80003f8c:	ec26                	sd	s1,24(sp)
    80003f8e:	e84a                	sd	s2,16(sp)
    80003f90:	e44e                	sd	s3,8(sp)
    80003f92:	1800                	addi	s0,sp,48
    80003f94:	892a                	mv	s2,a0
    80003f96:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f98:	0001d497          	auipc	s1,0x1d
    80003f9c:	2d848493          	addi	s1,s1,728 # 80021270 <log>
    80003fa0:	00004597          	auipc	a1,0x4
    80003fa4:	67858593          	addi	a1,a1,1656 # 80008618 <syscalls+0x1e8>
    80003fa8:	8526                	mv	a0,s1
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	b9c080e7          	jalr	-1124(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003fb2:	0149a583          	lw	a1,20(s3)
    80003fb6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fb8:	0109a783          	lw	a5,16(s3)
    80003fbc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fbe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fc2:	854a                	mv	a0,s2
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	e92080e7          	jalr	-366(ra) # 80002e56 <bread>
  log.lh.n = lh->n;
    80003fcc:	4d3c                	lw	a5,88(a0)
    80003fce:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fd0:	02f05563          	blez	a5,80003ffa <initlog+0x74>
    80003fd4:	05c50713          	addi	a4,a0,92
    80003fd8:	0001d697          	auipc	a3,0x1d
    80003fdc:	2c868693          	addi	a3,a3,712 # 800212a0 <log+0x30>
    80003fe0:	37fd                	addiw	a5,a5,-1
    80003fe2:	1782                	slli	a5,a5,0x20
    80003fe4:	9381                	srli	a5,a5,0x20
    80003fe6:	078a                	slli	a5,a5,0x2
    80003fe8:	06050613          	addi	a2,a0,96
    80003fec:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fee:	4310                	lw	a2,0(a4)
    80003ff0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003ff2:	0711                	addi	a4,a4,4
    80003ff4:	0691                	addi	a3,a3,4
    80003ff6:	fef71ce3          	bne	a4,a5,80003fee <initlog+0x68>
  brelse(buf);
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	f8c080e7          	jalr	-116(ra) # 80002f86 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004002:	4505                	li	a0,1
    80004004:	00000097          	auipc	ra,0x0
    80004008:	ebe080e7          	jalr	-322(ra) # 80003ec2 <install_trans>
  log.lh.n = 0;
    8000400c:	0001d797          	auipc	a5,0x1d
    80004010:	2807a823          	sw	zero,656(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004014:	00000097          	auipc	ra,0x0
    80004018:	e34080e7          	jalr	-460(ra) # 80003e48 <write_head>
}
    8000401c:	70a2                	ld	ra,40(sp)
    8000401e:	7402                	ld	s0,32(sp)
    80004020:	64e2                	ld	s1,24(sp)
    80004022:	6942                	ld	s2,16(sp)
    80004024:	69a2                	ld	s3,8(sp)
    80004026:	6145                	addi	sp,sp,48
    80004028:	8082                	ret

000000008000402a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000402a:	1101                	addi	sp,sp,-32
    8000402c:	ec06                	sd	ra,24(sp)
    8000402e:	e822                	sd	s0,16(sp)
    80004030:	e426                	sd	s1,8(sp)
    80004032:	e04a                	sd	s2,0(sp)
    80004034:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004036:	0001d517          	auipc	a0,0x1d
    8000403a:	23a50513          	addi	a0,a0,570 # 80021270 <log>
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	b98080e7          	jalr	-1128(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004046:	0001d497          	auipc	s1,0x1d
    8000404a:	22a48493          	addi	s1,s1,554 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000404e:	4979                	li	s2,30
    80004050:	a039                	j	8000405e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004052:	85a6                	mv	a1,s1
    80004054:	8526                	mv	a0,s1
    80004056:	ffffe097          	auipc	ra,0xffffe
    8000405a:	002080e7          	jalr	2(ra) # 80002058 <sleep>
    if(log.committing){
    8000405e:	50dc                	lw	a5,36(s1)
    80004060:	fbed                	bnez	a5,80004052 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004062:	509c                	lw	a5,32(s1)
    80004064:	0017871b          	addiw	a4,a5,1
    80004068:	0007069b          	sext.w	a3,a4
    8000406c:	0027179b          	slliw	a5,a4,0x2
    80004070:	9fb9                	addw	a5,a5,a4
    80004072:	0017979b          	slliw	a5,a5,0x1
    80004076:	54d8                	lw	a4,44(s1)
    80004078:	9fb9                	addw	a5,a5,a4
    8000407a:	00f95963          	bge	s2,a5,8000408c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000407e:	85a6                	mv	a1,s1
    80004080:	8526                	mv	a0,s1
    80004082:	ffffe097          	auipc	ra,0xffffe
    80004086:	fd6080e7          	jalr	-42(ra) # 80002058 <sleep>
    8000408a:	bfd1                	j	8000405e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000408c:	0001d517          	auipc	a0,0x1d
    80004090:	1e450513          	addi	a0,a0,484 # 80021270 <log>
    80004094:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	bf4080e7          	jalr	-1036(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000409e:	60e2                	ld	ra,24(sp)
    800040a0:	6442                	ld	s0,16(sp)
    800040a2:	64a2                	ld	s1,8(sp)
    800040a4:	6902                	ld	s2,0(sp)
    800040a6:	6105                	addi	sp,sp,32
    800040a8:	8082                	ret

00000000800040aa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040aa:	7139                	addi	sp,sp,-64
    800040ac:	fc06                	sd	ra,56(sp)
    800040ae:	f822                	sd	s0,48(sp)
    800040b0:	f426                	sd	s1,40(sp)
    800040b2:	f04a                	sd	s2,32(sp)
    800040b4:	ec4e                	sd	s3,24(sp)
    800040b6:	e852                	sd	s4,16(sp)
    800040b8:	e456                	sd	s5,8(sp)
    800040ba:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040bc:	0001d497          	auipc	s1,0x1d
    800040c0:	1b448493          	addi	s1,s1,436 # 80021270 <log>
    800040c4:	8526                	mv	a0,s1
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	b10080e7          	jalr	-1264(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800040ce:	509c                	lw	a5,32(s1)
    800040d0:	37fd                	addiw	a5,a5,-1
    800040d2:	0007891b          	sext.w	s2,a5
    800040d6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040d8:	50dc                	lw	a5,36(s1)
    800040da:	efb9                	bnez	a5,80004138 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040dc:	06091663          	bnez	s2,80004148 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040e0:	0001d497          	auipc	s1,0x1d
    800040e4:	19048493          	addi	s1,s1,400 # 80021270 <log>
    800040e8:	4785                	li	a5,1
    800040ea:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	b9c080e7          	jalr	-1124(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040f6:	54dc                	lw	a5,44(s1)
    800040f8:	06f04763          	bgtz	a5,80004166 <end_op+0xbc>
    acquire(&log.lock);
    800040fc:	0001d497          	auipc	s1,0x1d
    80004100:	17448493          	addi	s1,s1,372 # 80021270 <log>
    80004104:	8526                	mv	a0,s1
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	ad0080e7          	jalr	-1328(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000410e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004112:	8526                	mv	a0,s1
    80004114:	ffffe097          	auipc	ra,0xffffe
    80004118:	0d0080e7          	jalr	208(ra) # 800021e4 <wakeup>
    release(&log.lock);
    8000411c:	8526                	mv	a0,s1
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	b6c080e7          	jalr	-1172(ra) # 80000c8a <release>
}
    80004126:	70e2                	ld	ra,56(sp)
    80004128:	7442                	ld	s0,48(sp)
    8000412a:	74a2                	ld	s1,40(sp)
    8000412c:	7902                	ld	s2,32(sp)
    8000412e:	69e2                	ld	s3,24(sp)
    80004130:	6a42                	ld	s4,16(sp)
    80004132:	6aa2                	ld	s5,8(sp)
    80004134:	6121                	addi	sp,sp,64
    80004136:	8082                	ret
    panic("log.committing");
    80004138:	00004517          	auipc	a0,0x4
    8000413c:	4e850513          	addi	a0,a0,1256 # 80008620 <syscalls+0x1f0>
    80004140:	ffffc097          	auipc	ra,0xffffc
    80004144:	3f0080e7          	jalr	1008(ra) # 80000530 <panic>
    wakeup(&log);
    80004148:	0001d497          	auipc	s1,0x1d
    8000414c:	12848493          	addi	s1,s1,296 # 80021270 <log>
    80004150:	8526                	mv	a0,s1
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	092080e7          	jalr	146(ra) # 800021e4 <wakeup>
  release(&log.lock);
    8000415a:	8526                	mv	a0,s1
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
  if(do_commit){
    80004164:	b7c9                	j	80004126 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004166:	0001da97          	auipc	s5,0x1d
    8000416a:	13aa8a93          	addi	s5,s5,314 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000416e:	0001da17          	auipc	s4,0x1d
    80004172:	102a0a13          	addi	s4,s4,258 # 80021270 <log>
    80004176:	018a2583          	lw	a1,24(s4)
    8000417a:	012585bb          	addw	a1,a1,s2
    8000417e:	2585                	addiw	a1,a1,1
    80004180:	028a2503          	lw	a0,40(s4)
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	cd2080e7          	jalr	-814(ra) # 80002e56 <bread>
    8000418c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000418e:	000aa583          	lw	a1,0(s5)
    80004192:	028a2503          	lw	a0,40(s4)
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	cc0080e7          	jalr	-832(ra) # 80002e56 <bread>
    8000419e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041a0:	40000613          	li	a2,1024
    800041a4:	05850593          	addi	a1,a0,88
    800041a8:	05848513          	addi	a0,s1,88
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	b86080e7          	jalr	-1146(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	d92080e7          	jalr	-622(ra) # 80002f48 <bwrite>
    brelse(from);
    800041be:	854e                	mv	a0,s3
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	dc6080e7          	jalr	-570(ra) # 80002f86 <brelse>
    brelse(to);
    800041c8:	8526                	mv	a0,s1
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	dbc080e7          	jalr	-580(ra) # 80002f86 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d2:	2905                	addiw	s2,s2,1
    800041d4:	0a91                	addi	s5,s5,4
    800041d6:	02ca2783          	lw	a5,44(s4)
    800041da:	f8f94ee3          	blt	s2,a5,80004176 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	c6a080e7          	jalr	-918(ra) # 80003e48 <write_head>
    install_trans(0); // Now install writes to home locations
    800041e6:	4501                	li	a0,0
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	cda080e7          	jalr	-806(ra) # 80003ec2 <install_trans>
    log.lh.n = 0;
    800041f0:	0001d797          	auipc	a5,0x1d
    800041f4:	0a07a623          	sw	zero,172(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	c50080e7          	jalr	-944(ra) # 80003e48 <write_head>
    80004200:	bdf5                	j	800040fc <end_op+0x52>

0000000080004202 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004202:	1101                	addi	sp,sp,-32
    80004204:	ec06                	sd	ra,24(sp)
    80004206:	e822                	sd	s0,16(sp)
    80004208:	e426                	sd	s1,8(sp)
    8000420a:	e04a                	sd	s2,0(sp)
    8000420c:	1000                	addi	s0,sp,32
    8000420e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004210:	0001d917          	auipc	s2,0x1d
    80004214:	06090913          	addi	s2,s2,96 # 80021270 <log>
    80004218:	854a                	mv	a0,s2
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	9bc080e7          	jalr	-1604(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004222:	02c92603          	lw	a2,44(s2)
    80004226:	47f5                	li	a5,29
    80004228:	06c7c563          	blt	a5,a2,80004292 <log_write+0x90>
    8000422c:	0001d797          	auipc	a5,0x1d
    80004230:	0607a783          	lw	a5,96(a5) # 8002128c <log+0x1c>
    80004234:	37fd                	addiw	a5,a5,-1
    80004236:	04f65e63          	bge	a2,a5,80004292 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000423a:	0001d797          	auipc	a5,0x1d
    8000423e:	0567a783          	lw	a5,86(a5) # 80021290 <log+0x20>
    80004242:	06f05063          	blez	a5,800042a2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004246:	4781                	li	a5,0
    80004248:	06c05563          	blez	a2,800042b2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000424c:	44cc                	lw	a1,12(s1)
    8000424e:	0001d717          	auipc	a4,0x1d
    80004252:	05270713          	addi	a4,a4,82 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004256:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004258:	4314                	lw	a3,0(a4)
    8000425a:	04b68c63          	beq	a3,a1,800042b2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000425e:	2785                	addiw	a5,a5,1
    80004260:	0711                	addi	a4,a4,4
    80004262:	fef61be3          	bne	a2,a5,80004258 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004266:	0621                	addi	a2,a2,8
    80004268:	060a                	slli	a2,a2,0x2
    8000426a:	0001d797          	auipc	a5,0x1d
    8000426e:	00678793          	addi	a5,a5,6 # 80021270 <log>
    80004272:	963e                	add	a2,a2,a5
    80004274:	44dc                	lw	a5,12(s1)
    80004276:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004278:	8526                	mv	a0,s1
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	daa080e7          	jalr	-598(ra) # 80003024 <bpin>
    log.lh.n++;
    80004282:	0001d717          	auipc	a4,0x1d
    80004286:	fee70713          	addi	a4,a4,-18 # 80021270 <log>
    8000428a:	575c                	lw	a5,44(a4)
    8000428c:	2785                	addiw	a5,a5,1
    8000428e:	d75c                	sw	a5,44(a4)
    80004290:	a835                	j	800042cc <log_write+0xca>
    panic("too big a transaction");
    80004292:	00004517          	auipc	a0,0x4
    80004296:	39e50513          	addi	a0,a0,926 # 80008630 <syscalls+0x200>
    8000429a:	ffffc097          	auipc	ra,0xffffc
    8000429e:	296080e7          	jalr	662(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    800042a2:	00004517          	auipc	a0,0x4
    800042a6:	3a650513          	addi	a0,a0,934 # 80008648 <syscalls+0x218>
    800042aa:	ffffc097          	auipc	ra,0xffffc
    800042ae:	286080e7          	jalr	646(ra) # 80000530 <panic>
  log.lh.block[i] = b->blockno;
    800042b2:	00878713          	addi	a4,a5,8
    800042b6:	00271693          	slli	a3,a4,0x2
    800042ba:	0001d717          	auipc	a4,0x1d
    800042be:	fb670713          	addi	a4,a4,-74 # 80021270 <log>
    800042c2:	9736                	add	a4,a4,a3
    800042c4:	44d4                	lw	a3,12(s1)
    800042c6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042c8:	faf608e3          	beq	a2,a5,80004278 <log_write+0x76>
  }
  release(&log.lock);
    800042cc:	0001d517          	auipc	a0,0x1d
    800042d0:	fa450513          	addi	a0,a0,-92 # 80021270 <log>
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9b6080e7          	jalr	-1610(ra) # 80000c8a <release>
}
    800042dc:	60e2                	ld	ra,24(sp)
    800042de:	6442                	ld	s0,16(sp)
    800042e0:	64a2                	ld	s1,8(sp)
    800042e2:	6902                	ld	s2,0(sp)
    800042e4:	6105                	addi	sp,sp,32
    800042e6:	8082                	ret

00000000800042e8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042e8:	1101                	addi	sp,sp,-32
    800042ea:	ec06                	sd	ra,24(sp)
    800042ec:	e822                	sd	s0,16(sp)
    800042ee:	e426                	sd	s1,8(sp)
    800042f0:	e04a                	sd	s2,0(sp)
    800042f2:	1000                	addi	s0,sp,32
    800042f4:	84aa                	mv	s1,a0
    800042f6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042f8:	00004597          	auipc	a1,0x4
    800042fc:	37058593          	addi	a1,a1,880 # 80008668 <syscalls+0x238>
    80004300:	0521                	addi	a0,a0,8
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	844080e7          	jalr	-1980(ra) # 80000b46 <initlock>
  lk->name = name;
    8000430a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000430e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004312:	0204a423          	sw	zero,40(s1)
}
    80004316:	60e2                	ld	ra,24(sp)
    80004318:	6442                	ld	s0,16(sp)
    8000431a:	64a2                	ld	s1,8(sp)
    8000431c:	6902                	ld	s2,0(sp)
    8000431e:	6105                	addi	sp,sp,32
    80004320:	8082                	ret

0000000080004322 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004322:	1101                	addi	sp,sp,-32
    80004324:	ec06                	sd	ra,24(sp)
    80004326:	e822                	sd	s0,16(sp)
    80004328:	e426                	sd	s1,8(sp)
    8000432a:	e04a                	sd	s2,0(sp)
    8000432c:	1000                	addi	s0,sp,32
    8000432e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004330:	00850913          	addi	s2,a0,8
    80004334:	854a                	mv	a0,s2
    80004336:	ffffd097          	auipc	ra,0xffffd
    8000433a:	8a0080e7          	jalr	-1888(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000433e:	409c                	lw	a5,0(s1)
    80004340:	cb89                	beqz	a5,80004352 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004342:	85ca                	mv	a1,s2
    80004344:	8526                	mv	a0,s1
    80004346:	ffffe097          	auipc	ra,0xffffe
    8000434a:	d12080e7          	jalr	-750(ra) # 80002058 <sleep>
  while (lk->locked) {
    8000434e:	409c                	lw	a5,0(s1)
    80004350:	fbed                	bnez	a5,80004342 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004352:	4785                	li	a5,1
    80004354:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	63e080e7          	jalr	1598(ra) # 80001994 <myproc>
    8000435e:	591c                	lw	a5,48(a0)
    80004360:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004362:	854a                	mv	a0,s2
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	926080e7          	jalr	-1754(ra) # 80000c8a <release>
}
    8000436c:	60e2                	ld	ra,24(sp)
    8000436e:	6442                	ld	s0,16(sp)
    80004370:	64a2                	ld	s1,8(sp)
    80004372:	6902                	ld	s2,0(sp)
    80004374:	6105                	addi	sp,sp,32
    80004376:	8082                	ret

0000000080004378 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004378:	1101                	addi	sp,sp,-32
    8000437a:	ec06                	sd	ra,24(sp)
    8000437c:	e822                	sd	s0,16(sp)
    8000437e:	e426                	sd	s1,8(sp)
    80004380:	e04a                	sd	s2,0(sp)
    80004382:	1000                	addi	s0,sp,32
    80004384:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004386:	00850913          	addi	s2,a0,8
    8000438a:	854a                	mv	a0,s2
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	84a080e7          	jalr	-1974(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004394:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004398:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffe097          	auipc	ra,0xffffe
    800043a2:	e46080e7          	jalr	-442(ra) # 800021e4 <wakeup>
  release(&lk->lk);
    800043a6:	854a                	mv	a0,s2
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	8e2080e7          	jalr	-1822(ra) # 80000c8a <release>
}
    800043b0:	60e2                	ld	ra,24(sp)
    800043b2:	6442                	ld	s0,16(sp)
    800043b4:	64a2                	ld	s1,8(sp)
    800043b6:	6902                	ld	s2,0(sp)
    800043b8:	6105                	addi	sp,sp,32
    800043ba:	8082                	ret

00000000800043bc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043bc:	7179                	addi	sp,sp,-48
    800043be:	f406                	sd	ra,40(sp)
    800043c0:	f022                	sd	s0,32(sp)
    800043c2:	ec26                	sd	s1,24(sp)
    800043c4:	e84a                	sd	s2,16(sp)
    800043c6:	e44e                	sd	s3,8(sp)
    800043c8:	1800                	addi	s0,sp,48
    800043ca:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043cc:	00850913          	addi	s2,a0,8
    800043d0:	854a                	mv	a0,s2
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	804080e7          	jalr	-2044(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043da:	409c                	lw	a5,0(s1)
    800043dc:	ef99                	bnez	a5,800043fa <holdingsleep+0x3e>
    800043de:	4481                	li	s1,0
  release(&lk->lk);
    800043e0:	854a                	mv	a0,s2
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8a8080e7          	jalr	-1880(ra) # 80000c8a <release>
  return r;
}
    800043ea:	8526                	mv	a0,s1
    800043ec:	70a2                	ld	ra,40(sp)
    800043ee:	7402                	ld	s0,32(sp)
    800043f0:	64e2                	ld	s1,24(sp)
    800043f2:	6942                	ld	s2,16(sp)
    800043f4:	69a2                	ld	s3,8(sp)
    800043f6:	6145                	addi	sp,sp,48
    800043f8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043fa:	0284a983          	lw	s3,40(s1)
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	596080e7          	jalr	1430(ra) # 80001994 <myproc>
    80004406:	5904                	lw	s1,48(a0)
    80004408:	413484b3          	sub	s1,s1,s3
    8000440c:	0014b493          	seqz	s1,s1
    80004410:	bfc1                	j	800043e0 <holdingsleep+0x24>

0000000080004412 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004412:	1141                	addi	sp,sp,-16
    80004414:	e406                	sd	ra,8(sp)
    80004416:	e022                	sd	s0,0(sp)
    80004418:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000441a:	00004597          	auipc	a1,0x4
    8000441e:	25e58593          	addi	a1,a1,606 # 80008678 <syscalls+0x248>
    80004422:	0001d517          	auipc	a0,0x1d
    80004426:	f9650513          	addi	a0,a0,-106 # 800213b8 <ftable>
    8000442a:	ffffc097          	auipc	ra,0xffffc
    8000442e:	71c080e7          	jalr	1820(ra) # 80000b46 <initlock>
}
    80004432:	60a2                	ld	ra,8(sp)
    80004434:	6402                	ld	s0,0(sp)
    80004436:	0141                	addi	sp,sp,16
    80004438:	8082                	ret

000000008000443a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004444:	0001d517          	auipc	a0,0x1d
    80004448:	f7450513          	addi	a0,a0,-140 # 800213b8 <ftable>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	78a080e7          	jalr	1930(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004454:	0001d497          	auipc	s1,0x1d
    80004458:	f7c48493          	addi	s1,s1,-132 # 800213d0 <ftable+0x18>
    8000445c:	0001e717          	auipc	a4,0x1e
    80004460:	f1470713          	addi	a4,a4,-236 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004464:	40dc                	lw	a5,4(s1)
    80004466:	cf99                	beqz	a5,80004484 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004468:	02848493          	addi	s1,s1,40
    8000446c:	fee49ce3          	bne	s1,a4,80004464 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004470:	0001d517          	auipc	a0,0x1d
    80004474:	f4850513          	addi	a0,a0,-184 # 800213b8 <ftable>
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	812080e7          	jalr	-2030(ra) # 80000c8a <release>
  return 0;
    80004480:	4481                	li	s1,0
    80004482:	a819                	j	80004498 <filealloc+0x5e>
      f->ref = 1;
    80004484:	4785                	li	a5,1
    80004486:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004488:	0001d517          	auipc	a0,0x1d
    8000448c:	f3050513          	addi	a0,a0,-208 # 800213b8 <ftable>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	7fa080e7          	jalr	2042(ra) # 80000c8a <release>
}
    80004498:	8526                	mv	a0,s1
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret

00000000800044a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044a4:	1101                	addi	sp,sp,-32
    800044a6:	ec06                	sd	ra,24(sp)
    800044a8:	e822                	sd	s0,16(sp)
    800044aa:	e426                	sd	s1,8(sp)
    800044ac:	1000                	addi	s0,sp,32
    800044ae:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044b0:	0001d517          	auipc	a0,0x1d
    800044b4:	f0850513          	addi	a0,a0,-248 # 800213b8 <ftable>
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	71e080e7          	jalr	1822(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044c0:	40dc                	lw	a5,4(s1)
    800044c2:	02f05263          	blez	a5,800044e6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044c6:	2785                	addiw	a5,a5,1
    800044c8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044ca:	0001d517          	auipc	a0,0x1d
    800044ce:	eee50513          	addi	a0,a0,-274 # 800213b8 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7b8080e7          	jalr	1976(ra) # 80000c8a <release>
  return f;
}
    800044da:	8526                	mv	a0,s1
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	64a2                	ld	s1,8(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret
    panic("filedup");
    800044e6:	00004517          	auipc	a0,0x4
    800044ea:	19a50513          	addi	a0,a0,410 # 80008680 <syscalls+0x250>
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	042080e7          	jalr	66(ra) # 80000530 <panic>

00000000800044f6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044f6:	7139                	addi	sp,sp,-64
    800044f8:	fc06                	sd	ra,56(sp)
    800044fa:	f822                	sd	s0,48(sp)
    800044fc:	f426                	sd	s1,40(sp)
    800044fe:	f04a                	sd	s2,32(sp)
    80004500:	ec4e                	sd	s3,24(sp)
    80004502:	e852                	sd	s4,16(sp)
    80004504:	e456                	sd	s5,8(sp)
    80004506:	0080                	addi	s0,sp,64
    80004508:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	eae50513          	addi	a0,a0,-338 # 800213b8 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	6c4080e7          	jalr	1732(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000451a:	40dc                	lw	a5,4(s1)
    8000451c:	06f05163          	blez	a5,8000457e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004520:	37fd                	addiw	a5,a5,-1
    80004522:	0007871b          	sext.w	a4,a5
    80004526:	c0dc                	sw	a5,4(s1)
    80004528:	06e04363          	bgtz	a4,8000458e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000452c:	0004a903          	lw	s2,0(s1)
    80004530:	0094ca83          	lbu	s5,9(s1)
    80004534:	0104ba03          	ld	s4,16(s1)
    80004538:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000453c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004540:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004544:	0001d517          	auipc	a0,0x1d
    80004548:	e7450513          	addi	a0,a0,-396 # 800213b8 <ftable>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	73e080e7          	jalr	1854(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004554:	4785                	li	a5,1
    80004556:	04f90d63          	beq	s2,a5,800045b0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000455a:	3979                	addiw	s2,s2,-2
    8000455c:	4785                	li	a5,1
    8000455e:	0527e063          	bltu	a5,s2,8000459e <fileclose+0xa8>
    begin_op();
    80004562:	00000097          	auipc	ra,0x0
    80004566:	ac8080e7          	jalr	-1336(ra) # 8000402a <begin_op>
    iput(ff.ip);
    8000456a:	854e                	mv	a0,s3
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	2a6080e7          	jalr	678(ra) # 80003812 <iput>
    end_op();
    80004574:	00000097          	auipc	ra,0x0
    80004578:	b36080e7          	jalr	-1226(ra) # 800040aa <end_op>
    8000457c:	a00d                	j	8000459e <fileclose+0xa8>
    panic("fileclose");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	10a50513          	addi	a0,a0,266 # 80008688 <syscalls+0x258>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	faa080e7          	jalr	-86(ra) # 80000530 <panic>
    release(&ftable.lock);
    8000458e:	0001d517          	auipc	a0,0x1d
    80004592:	e2a50513          	addi	a0,a0,-470 # 800213b8 <ftable>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	6f4080e7          	jalr	1780(ra) # 80000c8a <release>
  }
}
    8000459e:	70e2                	ld	ra,56(sp)
    800045a0:	7442                	ld	s0,48(sp)
    800045a2:	74a2                	ld	s1,40(sp)
    800045a4:	7902                	ld	s2,32(sp)
    800045a6:	69e2                	ld	s3,24(sp)
    800045a8:	6a42                	ld	s4,16(sp)
    800045aa:	6aa2                	ld	s5,8(sp)
    800045ac:	6121                	addi	sp,sp,64
    800045ae:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045b0:	85d6                	mv	a1,s5
    800045b2:	8552                	mv	a0,s4
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	34c080e7          	jalr	844(ra) # 80004900 <pipeclose>
    800045bc:	b7cd                	j	8000459e <fileclose+0xa8>

00000000800045be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045be:	715d                	addi	sp,sp,-80
    800045c0:	e486                	sd	ra,72(sp)
    800045c2:	e0a2                	sd	s0,64(sp)
    800045c4:	fc26                	sd	s1,56(sp)
    800045c6:	f84a                	sd	s2,48(sp)
    800045c8:	f44e                	sd	s3,40(sp)
    800045ca:	0880                	addi	s0,sp,80
    800045cc:	84aa                	mv	s1,a0
    800045ce:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045d0:	ffffd097          	auipc	ra,0xffffd
    800045d4:	3c4080e7          	jalr	964(ra) # 80001994 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045d8:	409c                	lw	a5,0(s1)
    800045da:	37f9                	addiw	a5,a5,-2
    800045dc:	4705                	li	a4,1
    800045de:	04f76763          	bltu	a4,a5,8000462c <filestat+0x6e>
    800045e2:	892a                	mv	s2,a0
    ilock(f->ip);
    800045e4:	6c88                	ld	a0,24(s1)
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	072080e7          	jalr	114(ra) # 80003658 <ilock>
    stati(f->ip, &st);
    800045ee:	fb840593          	addi	a1,s0,-72
    800045f2:	6c88                	ld	a0,24(s1)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	2ee080e7          	jalr	750(ra) # 800038e2 <stati>
    iunlock(f->ip);
    800045fc:	6c88                	ld	a0,24(s1)
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	11c080e7          	jalr	284(ra) # 8000371a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004606:	46e1                	li	a3,24
    80004608:	fb840613          	addi	a2,s0,-72
    8000460c:	85ce                	mv	a1,s3
    8000460e:	05093503          	ld	a0,80(s2)
    80004612:	ffffd097          	auipc	ra,0xffffd
    80004616:	044080e7          	jalr	68(ra) # 80001656 <copyout>
    8000461a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000461e:	60a6                	ld	ra,72(sp)
    80004620:	6406                	ld	s0,64(sp)
    80004622:	74e2                	ld	s1,56(sp)
    80004624:	7942                	ld	s2,48(sp)
    80004626:	79a2                	ld	s3,40(sp)
    80004628:	6161                	addi	sp,sp,80
    8000462a:	8082                	ret
  return -1;
    8000462c:	557d                	li	a0,-1
    8000462e:	bfc5                	j	8000461e <filestat+0x60>

0000000080004630 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004630:	7179                	addi	sp,sp,-48
    80004632:	f406                	sd	ra,40(sp)
    80004634:	f022                	sd	s0,32(sp)
    80004636:	ec26                	sd	s1,24(sp)
    80004638:	e84a                	sd	s2,16(sp)
    8000463a:	e44e                	sd	s3,8(sp)
    8000463c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000463e:	00854783          	lbu	a5,8(a0)
    80004642:	c3d5                	beqz	a5,800046e6 <fileread+0xb6>
    80004644:	84aa                	mv	s1,a0
    80004646:	89ae                	mv	s3,a1
    80004648:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000464a:	411c                	lw	a5,0(a0)
    8000464c:	4705                	li	a4,1
    8000464e:	04e78963          	beq	a5,a4,800046a0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004652:	470d                	li	a4,3
    80004654:	04e78d63          	beq	a5,a4,800046ae <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004658:	4709                	li	a4,2
    8000465a:	06e79e63          	bne	a5,a4,800046d6 <fileread+0xa6>
    ilock(f->ip);
    8000465e:	6d08                	ld	a0,24(a0)
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	ff8080e7          	jalr	-8(ra) # 80003658 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004668:	874a                	mv	a4,s2
    8000466a:	5094                	lw	a3,32(s1)
    8000466c:	864e                	mv	a2,s3
    8000466e:	4585                	li	a1,1
    80004670:	6c88                	ld	a0,24(s1)
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	29a080e7          	jalr	666(ra) # 8000390c <readi>
    8000467a:	892a                	mv	s2,a0
    8000467c:	00a05563          	blez	a0,80004686 <fileread+0x56>
      f->off += r;
    80004680:	509c                	lw	a5,32(s1)
    80004682:	9fa9                	addw	a5,a5,a0
    80004684:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004686:	6c88                	ld	a0,24(s1)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	092080e7          	jalr	146(ra) # 8000371a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004690:	854a                	mv	a0,s2
    80004692:	70a2                	ld	ra,40(sp)
    80004694:	7402                	ld	s0,32(sp)
    80004696:	64e2                	ld	s1,24(sp)
    80004698:	6942                	ld	s2,16(sp)
    8000469a:	69a2                	ld	s3,8(sp)
    8000469c:	6145                	addi	sp,sp,48
    8000469e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046a0:	6908                	ld	a0,16(a0)
    800046a2:	00000097          	auipc	ra,0x0
    800046a6:	3c8080e7          	jalr	968(ra) # 80004a6a <piperead>
    800046aa:	892a                	mv	s2,a0
    800046ac:	b7d5                	j	80004690 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046ae:	02451783          	lh	a5,36(a0)
    800046b2:	03079693          	slli	a3,a5,0x30
    800046b6:	92c1                	srli	a3,a3,0x30
    800046b8:	4725                	li	a4,9
    800046ba:	02d76863          	bltu	a4,a3,800046ea <fileread+0xba>
    800046be:	0792                	slli	a5,a5,0x4
    800046c0:	0001d717          	auipc	a4,0x1d
    800046c4:	c5870713          	addi	a4,a4,-936 # 80021318 <devsw>
    800046c8:	97ba                	add	a5,a5,a4
    800046ca:	639c                	ld	a5,0(a5)
    800046cc:	c38d                	beqz	a5,800046ee <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046ce:	4505                	li	a0,1
    800046d0:	9782                	jalr	a5
    800046d2:	892a                	mv	s2,a0
    800046d4:	bf75                	j	80004690 <fileread+0x60>
    panic("fileread");
    800046d6:	00004517          	auipc	a0,0x4
    800046da:	fc250513          	addi	a0,a0,-62 # 80008698 <syscalls+0x268>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	e52080e7          	jalr	-430(ra) # 80000530 <panic>
    return -1;
    800046e6:	597d                	li	s2,-1
    800046e8:	b765                	j	80004690 <fileread+0x60>
      return -1;
    800046ea:	597d                	li	s2,-1
    800046ec:	b755                	j	80004690 <fileread+0x60>
    800046ee:	597d                	li	s2,-1
    800046f0:	b745                	j	80004690 <fileread+0x60>

00000000800046f2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046f2:	715d                	addi	sp,sp,-80
    800046f4:	e486                	sd	ra,72(sp)
    800046f6:	e0a2                	sd	s0,64(sp)
    800046f8:	fc26                	sd	s1,56(sp)
    800046fa:	f84a                	sd	s2,48(sp)
    800046fc:	f44e                	sd	s3,40(sp)
    800046fe:	f052                	sd	s4,32(sp)
    80004700:	ec56                	sd	s5,24(sp)
    80004702:	e85a                	sd	s6,16(sp)
    80004704:	e45e                	sd	s7,8(sp)
    80004706:	e062                	sd	s8,0(sp)
    80004708:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000470a:	00954783          	lbu	a5,9(a0)
    8000470e:	10078663          	beqz	a5,8000481a <filewrite+0x128>
    80004712:	892a                	mv	s2,a0
    80004714:	8aae                	mv	s5,a1
    80004716:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004718:	411c                	lw	a5,0(a0)
    8000471a:	4705                	li	a4,1
    8000471c:	02e78263          	beq	a5,a4,80004740 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004720:	470d                	li	a4,3
    80004722:	02e78663          	beq	a5,a4,8000474e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004726:	4709                	li	a4,2
    80004728:	0ee79163          	bne	a5,a4,8000480a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000472c:	0ac05d63          	blez	a2,800047e6 <filewrite+0xf4>
    int i = 0;
    80004730:	4981                	li	s3,0
    80004732:	6b05                	lui	s6,0x1
    80004734:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004738:	6b85                	lui	s7,0x1
    8000473a:	c00b8b9b          	addiw	s7,s7,-1024
    8000473e:	a861                	j	800047d6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004740:	6908                	ld	a0,16(a0)
    80004742:	00000097          	auipc	ra,0x0
    80004746:	22e080e7          	jalr	558(ra) # 80004970 <pipewrite>
    8000474a:	8a2a                	mv	s4,a0
    8000474c:	a045                	j	800047ec <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000474e:	02451783          	lh	a5,36(a0)
    80004752:	03079693          	slli	a3,a5,0x30
    80004756:	92c1                	srli	a3,a3,0x30
    80004758:	4725                	li	a4,9
    8000475a:	0cd76263          	bltu	a4,a3,8000481e <filewrite+0x12c>
    8000475e:	0792                	slli	a5,a5,0x4
    80004760:	0001d717          	auipc	a4,0x1d
    80004764:	bb870713          	addi	a4,a4,-1096 # 80021318 <devsw>
    80004768:	97ba                	add	a5,a5,a4
    8000476a:	679c                	ld	a5,8(a5)
    8000476c:	cbdd                	beqz	a5,80004822 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000476e:	4505                	li	a0,1
    80004770:	9782                	jalr	a5
    80004772:	8a2a                	mv	s4,a0
    80004774:	a8a5                	j	800047ec <filewrite+0xfa>
    80004776:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	8b0080e7          	jalr	-1872(ra) # 8000402a <begin_op>
      ilock(f->ip);
    80004782:	01893503          	ld	a0,24(s2)
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	ed2080e7          	jalr	-302(ra) # 80003658 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000478e:	8762                	mv	a4,s8
    80004790:	02092683          	lw	a3,32(s2)
    80004794:	01598633          	add	a2,s3,s5
    80004798:	4585                	li	a1,1
    8000479a:	01893503          	ld	a0,24(s2)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	266080e7          	jalr	614(ra) # 80003a04 <writei>
    800047a6:	84aa                	mv	s1,a0
    800047a8:	00a05763          	blez	a0,800047b6 <filewrite+0xc4>
        f->off += r;
    800047ac:	02092783          	lw	a5,32(s2)
    800047b0:	9fa9                	addw	a5,a5,a0
    800047b2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047b6:	01893503          	ld	a0,24(s2)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	f60080e7          	jalr	-160(ra) # 8000371a <iunlock>
      end_op();
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	8e8080e7          	jalr	-1816(ra) # 800040aa <end_op>

      if(r != n1){
    800047ca:	009c1f63          	bne	s8,s1,800047e8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047ce:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047d2:	0149db63          	bge	s3,s4,800047e8 <filewrite+0xf6>
      int n1 = n - i;
    800047d6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047da:	84be                	mv	s1,a5
    800047dc:	2781                	sext.w	a5,a5
    800047de:	f8fb5ce3          	bge	s6,a5,80004776 <filewrite+0x84>
    800047e2:	84de                	mv	s1,s7
    800047e4:	bf49                	j	80004776 <filewrite+0x84>
    int i = 0;
    800047e6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047e8:	013a1f63          	bne	s4,s3,80004806 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047ec:	8552                	mv	a0,s4
    800047ee:	60a6                	ld	ra,72(sp)
    800047f0:	6406                	ld	s0,64(sp)
    800047f2:	74e2                	ld	s1,56(sp)
    800047f4:	7942                	ld	s2,48(sp)
    800047f6:	79a2                	ld	s3,40(sp)
    800047f8:	7a02                	ld	s4,32(sp)
    800047fa:	6ae2                	ld	s5,24(sp)
    800047fc:	6b42                	ld	s6,16(sp)
    800047fe:	6ba2                	ld	s7,8(sp)
    80004800:	6c02                	ld	s8,0(sp)
    80004802:	6161                	addi	sp,sp,80
    80004804:	8082                	ret
    ret = (i == n ? n : -1);
    80004806:	5a7d                	li	s4,-1
    80004808:	b7d5                	j	800047ec <filewrite+0xfa>
    panic("filewrite");
    8000480a:	00004517          	auipc	a0,0x4
    8000480e:	e9e50513          	addi	a0,a0,-354 # 800086a8 <syscalls+0x278>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	d1e080e7          	jalr	-738(ra) # 80000530 <panic>
    return -1;
    8000481a:	5a7d                	li	s4,-1
    8000481c:	bfc1                	j	800047ec <filewrite+0xfa>
      return -1;
    8000481e:	5a7d                	li	s4,-1
    80004820:	b7f1                	j	800047ec <filewrite+0xfa>
    80004822:	5a7d                	li	s4,-1
    80004824:	b7e1                	j	800047ec <filewrite+0xfa>

0000000080004826 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004826:	7179                	addi	sp,sp,-48
    80004828:	f406                	sd	ra,40(sp)
    8000482a:	f022                	sd	s0,32(sp)
    8000482c:	ec26                	sd	s1,24(sp)
    8000482e:	e84a                	sd	s2,16(sp)
    80004830:	e44e                	sd	s3,8(sp)
    80004832:	e052                	sd	s4,0(sp)
    80004834:	1800                	addi	s0,sp,48
    80004836:	84aa                	mv	s1,a0
    80004838:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000483a:	0005b023          	sd	zero,0(a1)
    8000483e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004842:	00000097          	auipc	ra,0x0
    80004846:	bf8080e7          	jalr	-1032(ra) # 8000443a <filealloc>
    8000484a:	e088                	sd	a0,0(s1)
    8000484c:	c551                	beqz	a0,800048d8 <pipealloc+0xb2>
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	bec080e7          	jalr	-1044(ra) # 8000443a <filealloc>
    80004856:	00aa3023          	sd	a0,0(s4)
    8000485a:	c92d                	beqz	a0,800048cc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	28a080e7          	jalr	650(ra) # 80000ae6 <kalloc>
    80004864:	892a                	mv	s2,a0
    80004866:	c125                	beqz	a0,800048c6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004868:	4985                	li	s3,1
    8000486a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000486e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004872:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004876:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000487a:	00004597          	auipc	a1,0x4
    8000487e:	e3e58593          	addi	a1,a1,-450 # 800086b8 <syscalls+0x288>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	2c4080e7          	jalr	708(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000488a:	609c                	ld	a5,0(s1)
    8000488c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004890:	609c                	ld	a5,0(s1)
    80004892:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004896:	609c                	ld	a5,0(s1)
    80004898:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000489c:	609c                	ld	a5,0(s1)
    8000489e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048a2:	000a3783          	ld	a5,0(s4)
    800048a6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048aa:	000a3783          	ld	a5,0(s4)
    800048ae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048b2:	000a3783          	ld	a5,0(s4)
    800048b6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048ba:	000a3783          	ld	a5,0(s4)
    800048be:	0127b823          	sd	s2,16(a5)
  return 0;
    800048c2:	4501                	li	a0,0
    800048c4:	a025                	j	800048ec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048c6:	6088                	ld	a0,0(s1)
    800048c8:	e501                	bnez	a0,800048d0 <pipealloc+0xaa>
    800048ca:	a039                	j	800048d8 <pipealloc+0xb2>
    800048cc:	6088                	ld	a0,0(s1)
    800048ce:	c51d                	beqz	a0,800048fc <pipealloc+0xd6>
    fileclose(*f0);
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	c26080e7          	jalr	-986(ra) # 800044f6 <fileclose>
  if(*f1)
    800048d8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048dc:	557d                	li	a0,-1
  if(*f1)
    800048de:	c799                	beqz	a5,800048ec <pipealloc+0xc6>
    fileclose(*f1);
    800048e0:	853e                	mv	a0,a5
    800048e2:	00000097          	auipc	ra,0x0
    800048e6:	c14080e7          	jalr	-1004(ra) # 800044f6 <fileclose>
  return -1;
    800048ea:	557d                	li	a0,-1
}
    800048ec:	70a2                	ld	ra,40(sp)
    800048ee:	7402                	ld	s0,32(sp)
    800048f0:	64e2                	ld	s1,24(sp)
    800048f2:	6942                	ld	s2,16(sp)
    800048f4:	69a2                	ld	s3,8(sp)
    800048f6:	6a02                	ld	s4,0(sp)
    800048f8:	6145                	addi	sp,sp,48
    800048fa:	8082                	ret
  return -1;
    800048fc:	557d                	li	a0,-1
    800048fe:	b7fd                	j	800048ec <pipealloc+0xc6>

0000000080004900 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004900:	1101                	addi	sp,sp,-32
    80004902:	ec06                	sd	ra,24(sp)
    80004904:	e822                	sd	s0,16(sp)
    80004906:	e426                	sd	s1,8(sp)
    80004908:	e04a                	sd	s2,0(sp)
    8000490a:	1000                	addi	s0,sp,32
    8000490c:	84aa                	mv	s1,a0
    8000490e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	2c6080e7          	jalr	710(ra) # 80000bd6 <acquire>
  if(writable){
    80004918:	02090d63          	beqz	s2,80004952 <pipeclose+0x52>
    pi->writeopen = 0;
    8000491c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004920:	21848513          	addi	a0,s1,536
    80004924:	ffffe097          	auipc	ra,0xffffe
    80004928:	8c0080e7          	jalr	-1856(ra) # 800021e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000492c:	2204b783          	ld	a5,544(s1)
    80004930:	eb95                	bnez	a5,80004964 <pipeclose+0x64>
    release(&pi->lock);
    80004932:	8526                	mv	a0,s1
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	356080e7          	jalr	854(ra) # 80000c8a <release>
    kfree((char*)pi);
    8000493c:	8526                	mv	a0,s1
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	0ac080e7          	jalr	172(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004946:	60e2                	ld	ra,24(sp)
    80004948:	6442                	ld	s0,16(sp)
    8000494a:	64a2                	ld	s1,8(sp)
    8000494c:	6902                	ld	s2,0(sp)
    8000494e:	6105                	addi	sp,sp,32
    80004950:	8082                	ret
    pi->readopen = 0;
    80004952:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004956:	21c48513          	addi	a0,s1,540
    8000495a:	ffffe097          	auipc	ra,0xffffe
    8000495e:	88a080e7          	jalr	-1910(ra) # 800021e4 <wakeup>
    80004962:	b7e9                	j	8000492c <pipeclose+0x2c>
    release(&pi->lock);
    80004964:	8526                	mv	a0,s1
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	324080e7          	jalr	804(ra) # 80000c8a <release>
}
    8000496e:	bfe1                	j	80004946 <pipeclose+0x46>

0000000080004970 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004970:	7159                	addi	sp,sp,-112
    80004972:	f486                	sd	ra,104(sp)
    80004974:	f0a2                	sd	s0,96(sp)
    80004976:	eca6                	sd	s1,88(sp)
    80004978:	e8ca                	sd	s2,80(sp)
    8000497a:	e4ce                	sd	s3,72(sp)
    8000497c:	e0d2                	sd	s4,64(sp)
    8000497e:	fc56                	sd	s5,56(sp)
    80004980:	f85a                	sd	s6,48(sp)
    80004982:	f45e                	sd	s7,40(sp)
    80004984:	f062                	sd	s8,32(sp)
    80004986:	ec66                	sd	s9,24(sp)
    80004988:	1880                	addi	s0,sp,112
    8000498a:	84aa                	mv	s1,a0
    8000498c:	8aae                	mv	s5,a1
    8000498e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004990:	ffffd097          	auipc	ra,0xffffd
    80004994:	004080e7          	jalr	4(ra) # 80001994 <myproc>
    80004998:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000499a:	8526                	mv	a0,s1
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	23a080e7          	jalr	570(ra) # 80000bd6 <acquire>
  while(i < n){
    800049a4:	0d405163          	blez	s4,80004a66 <pipewrite+0xf6>
    800049a8:	8ba6                	mv	s7,s1
  int i = 0;
    800049aa:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ac:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049ae:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049b2:	21c48c13          	addi	s8,s1,540
    800049b6:	a08d                	j	80004a18 <pipewrite+0xa8>
      release(&pi->lock);
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	2d0080e7          	jalr	720(ra) # 80000c8a <release>
      return -1;
    800049c2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049c4:	854a                	mv	a0,s2
    800049c6:	70a6                	ld	ra,104(sp)
    800049c8:	7406                	ld	s0,96(sp)
    800049ca:	64e6                	ld	s1,88(sp)
    800049cc:	6946                	ld	s2,80(sp)
    800049ce:	69a6                	ld	s3,72(sp)
    800049d0:	6a06                	ld	s4,64(sp)
    800049d2:	7ae2                	ld	s5,56(sp)
    800049d4:	7b42                	ld	s6,48(sp)
    800049d6:	7ba2                	ld	s7,40(sp)
    800049d8:	7c02                	ld	s8,32(sp)
    800049da:	6ce2                	ld	s9,24(sp)
    800049dc:	6165                	addi	sp,sp,112
    800049de:	8082                	ret
      wakeup(&pi->nread);
    800049e0:	8566                	mv	a0,s9
    800049e2:	ffffe097          	auipc	ra,0xffffe
    800049e6:	802080e7          	jalr	-2046(ra) # 800021e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049ea:	85de                	mv	a1,s7
    800049ec:	8562                	mv	a0,s8
    800049ee:	ffffd097          	auipc	ra,0xffffd
    800049f2:	66a080e7          	jalr	1642(ra) # 80002058 <sleep>
    800049f6:	a839                	j	80004a14 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049f8:	21c4a783          	lw	a5,540(s1)
    800049fc:	0017871b          	addiw	a4,a5,1
    80004a00:	20e4ae23          	sw	a4,540(s1)
    80004a04:	1ff7f793          	andi	a5,a5,511
    80004a08:	97a6                	add	a5,a5,s1
    80004a0a:	f9f44703          	lbu	a4,-97(s0)
    80004a0e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a12:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a14:	03495d63          	bge	s2,s4,80004a4e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a18:	2204a783          	lw	a5,544(s1)
    80004a1c:	dfd1                	beqz	a5,800049b8 <pipewrite+0x48>
    80004a1e:	0289a783          	lw	a5,40(s3)
    80004a22:	fbd9                	bnez	a5,800049b8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a24:	2184a783          	lw	a5,536(s1)
    80004a28:	21c4a703          	lw	a4,540(s1)
    80004a2c:	2007879b          	addiw	a5,a5,512
    80004a30:	faf708e3          	beq	a4,a5,800049e0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a34:	4685                	li	a3,1
    80004a36:	01590633          	add	a2,s2,s5
    80004a3a:	f9f40593          	addi	a1,s0,-97
    80004a3e:	0509b503          	ld	a0,80(s3)
    80004a42:	ffffd097          	auipc	ra,0xffffd
    80004a46:	ca0080e7          	jalr	-864(ra) # 800016e2 <copyin>
    80004a4a:	fb6517e3          	bne	a0,s6,800049f8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a4e:	21848513          	addi	a0,s1,536
    80004a52:	ffffd097          	auipc	ra,0xffffd
    80004a56:	792080e7          	jalr	1938(ra) # 800021e4 <wakeup>
  release(&pi->lock);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	22e080e7          	jalr	558(ra) # 80000c8a <release>
  return i;
    80004a64:	b785                	j	800049c4 <pipewrite+0x54>
  int i = 0;
    80004a66:	4901                	li	s2,0
    80004a68:	b7dd                	j	80004a4e <pipewrite+0xde>

0000000080004a6a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a6a:	715d                	addi	sp,sp,-80
    80004a6c:	e486                	sd	ra,72(sp)
    80004a6e:	e0a2                	sd	s0,64(sp)
    80004a70:	fc26                	sd	s1,56(sp)
    80004a72:	f84a                	sd	s2,48(sp)
    80004a74:	f44e                	sd	s3,40(sp)
    80004a76:	f052                	sd	s4,32(sp)
    80004a78:	ec56                	sd	s5,24(sp)
    80004a7a:	e85a                	sd	s6,16(sp)
    80004a7c:	0880                	addi	s0,sp,80
    80004a7e:	84aa                	mv	s1,a0
    80004a80:	892e                	mv	s2,a1
    80004a82:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	f10080e7          	jalr	-240(ra) # 80001994 <myproc>
    80004a8c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a8e:	8b26                	mv	s6,s1
    80004a90:	8526                	mv	a0,s1
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	144080e7          	jalr	324(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a9a:	2184a703          	lw	a4,536(s1)
    80004a9e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aa6:	02f71463          	bne	a4,a5,80004ace <piperead+0x64>
    80004aaa:	2244a783          	lw	a5,548(s1)
    80004aae:	c385                	beqz	a5,80004ace <piperead+0x64>
    if(pr->killed){
    80004ab0:	028a2783          	lw	a5,40(s4)
    80004ab4:	ebc1                	bnez	a5,80004b44 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ab6:	85da                	mv	a1,s6
    80004ab8:	854e                	mv	a0,s3
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	59e080e7          	jalr	1438(ra) # 80002058 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ac2:	2184a703          	lw	a4,536(s1)
    80004ac6:	21c4a783          	lw	a5,540(s1)
    80004aca:	fef700e3          	beq	a4,a5,80004aaa <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ace:	09505263          	blez	s5,80004b52 <piperead+0xe8>
    80004ad2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ad4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ad6:	2184a783          	lw	a5,536(s1)
    80004ada:	21c4a703          	lw	a4,540(s1)
    80004ade:	02f70d63          	beq	a4,a5,80004b18 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ae2:	0017871b          	addiw	a4,a5,1
    80004ae6:	20e4ac23          	sw	a4,536(s1)
    80004aea:	1ff7f793          	andi	a5,a5,511
    80004aee:	97a6                	add	a5,a5,s1
    80004af0:	0187c783          	lbu	a5,24(a5)
    80004af4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004af8:	4685                	li	a3,1
    80004afa:	fbf40613          	addi	a2,s0,-65
    80004afe:	85ca                	mv	a1,s2
    80004b00:	050a3503          	ld	a0,80(s4)
    80004b04:	ffffd097          	auipc	ra,0xffffd
    80004b08:	b52080e7          	jalr	-1198(ra) # 80001656 <copyout>
    80004b0c:	01650663          	beq	a0,s6,80004b18 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b10:	2985                	addiw	s3,s3,1
    80004b12:	0905                	addi	s2,s2,1
    80004b14:	fd3a91e3          	bne	s5,s3,80004ad6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b18:	21c48513          	addi	a0,s1,540
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	6c8080e7          	jalr	1736(ra) # 800021e4 <wakeup>
  release(&pi->lock);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	164080e7          	jalr	356(ra) # 80000c8a <release>
  return i;
}
    80004b2e:	854e                	mv	a0,s3
    80004b30:	60a6                	ld	ra,72(sp)
    80004b32:	6406                	ld	s0,64(sp)
    80004b34:	74e2                	ld	s1,56(sp)
    80004b36:	7942                	ld	s2,48(sp)
    80004b38:	79a2                	ld	s3,40(sp)
    80004b3a:	7a02                	ld	s4,32(sp)
    80004b3c:	6ae2                	ld	s5,24(sp)
    80004b3e:	6b42                	ld	s6,16(sp)
    80004b40:	6161                	addi	sp,sp,80
    80004b42:	8082                	ret
      release(&pi->lock);
    80004b44:	8526                	mv	a0,s1
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	144080e7          	jalr	324(ra) # 80000c8a <release>
      return -1;
    80004b4e:	59fd                	li	s3,-1
    80004b50:	bff9                	j	80004b2e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b52:	4981                	li	s3,0
    80004b54:	b7d1                	j	80004b18 <piperead+0xae>

0000000080004b56 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b56:	df010113          	addi	sp,sp,-528
    80004b5a:	20113423          	sd	ra,520(sp)
    80004b5e:	20813023          	sd	s0,512(sp)
    80004b62:	ffa6                	sd	s1,504(sp)
    80004b64:	fbca                	sd	s2,496(sp)
    80004b66:	f7ce                	sd	s3,488(sp)
    80004b68:	f3d2                	sd	s4,480(sp)
    80004b6a:	efd6                	sd	s5,472(sp)
    80004b6c:	ebda                	sd	s6,464(sp)
    80004b6e:	e7de                	sd	s7,456(sp)
    80004b70:	e3e2                	sd	s8,448(sp)
    80004b72:	ff66                	sd	s9,440(sp)
    80004b74:	fb6a                	sd	s10,432(sp)
    80004b76:	f76e                	sd	s11,424(sp)
    80004b78:	0c00                	addi	s0,sp,528
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	dea43c23          	sd	a0,-520(s0)
    80004b80:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b84:	ffffd097          	auipc	ra,0xffffd
    80004b88:	e10080e7          	jalr	-496(ra) # 80001994 <myproc>
    80004b8c:	892a                	mv	s2,a0

  begin_op();
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	49c080e7          	jalr	1180(ra) # 8000402a <begin_op>

  if((ip = namei(path)) == 0){
    80004b96:	8526                	mv	a0,s1
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	276080e7          	jalr	630(ra) # 80003e0e <namei>
    80004ba0:	c92d                	beqz	a0,80004c12 <exec+0xbc>
    80004ba2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	ab4080e7          	jalr	-1356(ra) # 80003658 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bac:	04000713          	li	a4,64
    80004bb0:	4681                	li	a3,0
    80004bb2:	e4840613          	addi	a2,s0,-440
    80004bb6:	4581                	li	a1,0
    80004bb8:	8526                	mv	a0,s1
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	d52080e7          	jalr	-686(ra) # 8000390c <readi>
    80004bc2:	04000793          	li	a5,64
    80004bc6:	00f51a63          	bne	a0,a5,80004bda <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004bca:	e4842703          	lw	a4,-440(s0)
    80004bce:	464c47b7          	lui	a5,0x464c4
    80004bd2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bd6:	04f70463          	beq	a4,a5,80004c1e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bda:	8526                	mv	a0,s1
    80004bdc:	fffff097          	auipc	ra,0xfffff
    80004be0:	cde080e7          	jalr	-802(ra) # 800038ba <iunlockput>
    end_op();
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	4c6080e7          	jalr	1222(ra) # 800040aa <end_op>
  }
  return -1;
    80004bec:	557d                	li	a0,-1
}
    80004bee:	20813083          	ld	ra,520(sp)
    80004bf2:	20013403          	ld	s0,512(sp)
    80004bf6:	74fe                	ld	s1,504(sp)
    80004bf8:	795e                	ld	s2,496(sp)
    80004bfa:	79be                	ld	s3,488(sp)
    80004bfc:	7a1e                	ld	s4,480(sp)
    80004bfe:	6afe                	ld	s5,472(sp)
    80004c00:	6b5e                	ld	s6,464(sp)
    80004c02:	6bbe                	ld	s7,456(sp)
    80004c04:	6c1e                	ld	s8,448(sp)
    80004c06:	7cfa                	ld	s9,440(sp)
    80004c08:	7d5a                	ld	s10,432(sp)
    80004c0a:	7dba                	ld	s11,424(sp)
    80004c0c:	21010113          	addi	sp,sp,528
    80004c10:	8082                	ret
    end_op();
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	498080e7          	jalr	1176(ra) # 800040aa <end_op>
    return -1;
    80004c1a:	557d                	li	a0,-1
    80004c1c:	bfc9                	j	80004bee <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c1e:	854a                	mv	a0,s2
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	e38080e7          	jalr	-456(ra) # 80001a58 <proc_pagetable>
    80004c28:	8baa                	mv	s7,a0
    80004c2a:	d945                	beqz	a0,80004bda <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c2c:	e6842983          	lw	s3,-408(s0)
    80004c30:	e8045783          	lhu	a5,-384(s0)
    80004c34:	c7ad                	beqz	a5,80004c9e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c36:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c38:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004c3a:	6c85                	lui	s9,0x1
    80004c3c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c40:	def43823          	sd	a5,-528(s0)
    80004c44:	a42d                	j	80004e6e <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c46:	00004517          	auipc	a0,0x4
    80004c4a:	a7a50513          	addi	a0,a0,-1414 # 800086c0 <syscalls+0x290>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	8e2080e7          	jalr	-1822(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c56:	8756                	mv	a4,s5
    80004c58:	012d86bb          	addw	a3,s11,s2
    80004c5c:	4581                	li	a1,0
    80004c5e:	8526                	mv	a0,s1
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	cac080e7          	jalr	-852(ra) # 8000390c <readi>
    80004c68:	2501                	sext.w	a0,a0
    80004c6a:	1aaa9963          	bne	s5,a0,80004e1c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c6e:	6785                	lui	a5,0x1
    80004c70:	0127893b          	addw	s2,a5,s2
    80004c74:	77fd                	lui	a5,0xfffff
    80004c76:	01478a3b          	addw	s4,a5,s4
    80004c7a:	1f897163          	bgeu	s2,s8,80004e5c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c7e:	02091593          	slli	a1,s2,0x20
    80004c82:	9181                	srli	a1,a1,0x20
    80004c84:	95ea                	add	a1,a1,s10
    80004c86:	855e                	mv	a0,s7
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	3dc080e7          	jalr	988(ra) # 80001064 <walkaddr>
    80004c90:	862a                	mv	a2,a0
    if(pa == 0)
    80004c92:	d955                	beqz	a0,80004c46 <exec+0xf0>
      n = PGSIZE;
    80004c94:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c96:	fd9a70e3          	bgeu	s4,s9,80004c56 <exec+0x100>
      n = sz - i;
    80004c9a:	8ad2                	mv	s5,s4
    80004c9c:	bf6d                	j	80004c56 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c9e:	4901                	li	s2,0
  iunlockput(ip);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	c18080e7          	jalr	-1000(ra) # 800038ba <iunlockput>
  end_op();
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	400080e7          	jalr	1024(ra) # 800040aa <end_op>
  p = myproc();
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	ce2080e7          	jalr	-798(ra) # 80001994 <myproc>
    80004cba:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004cbc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cc0:	6785                	lui	a5,0x1
    80004cc2:	17fd                	addi	a5,a5,-1
    80004cc4:	993e                	add	s2,s2,a5
    80004cc6:	757d                	lui	a0,0xfffff
    80004cc8:	00a977b3          	and	a5,s2,a0
    80004ccc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cd0:	6609                	lui	a2,0x2
    80004cd2:	963e                	add	a2,a2,a5
    80004cd4:	85be                	mv	a1,a5
    80004cd6:	855e                	mv	a0,s7
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	72e080e7          	jalr	1838(ra) # 80001406 <uvmalloc>
    80004ce0:	8b2a                	mv	s6,a0
  ip = 0;
    80004ce2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ce4:	12050c63          	beqz	a0,80004e1c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ce8:	75f9                	lui	a1,0xffffe
    80004cea:	95aa                	add	a1,a1,a0
    80004cec:	855e                	mv	a0,s7
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	936080e7          	jalr	-1738(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004cf6:	7c7d                	lui	s8,0xfffff
    80004cf8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004cfa:	e0043783          	ld	a5,-512(s0)
    80004cfe:	6388                	ld	a0,0(a5)
    80004d00:	c535                	beqz	a0,80004d6c <exec+0x216>
    80004d02:	e8840993          	addi	s3,s0,-376
    80004d06:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d0a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	14e080e7          	jalr	334(ra) # 80000e5a <strlen>
    80004d14:	2505                	addiw	a0,a0,1
    80004d16:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d1a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d1e:	13896363          	bltu	s2,s8,80004e44 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d22:	e0043d83          	ld	s11,-512(s0)
    80004d26:	000dba03          	ld	s4,0(s11)
    80004d2a:	8552                	mv	a0,s4
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	12e080e7          	jalr	302(ra) # 80000e5a <strlen>
    80004d34:	0015069b          	addiw	a3,a0,1
    80004d38:	8652                	mv	a2,s4
    80004d3a:	85ca                	mv	a1,s2
    80004d3c:	855e                	mv	a0,s7
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	918080e7          	jalr	-1768(ra) # 80001656 <copyout>
    80004d46:	10054363          	bltz	a0,80004e4c <exec+0x2f6>
    ustack[argc] = sp;
    80004d4a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d4e:	0485                	addi	s1,s1,1
    80004d50:	008d8793          	addi	a5,s11,8
    80004d54:	e0f43023          	sd	a5,-512(s0)
    80004d58:	008db503          	ld	a0,8(s11)
    80004d5c:	c911                	beqz	a0,80004d70 <exec+0x21a>
    if(argc >= MAXARG)
    80004d5e:	09a1                	addi	s3,s3,8
    80004d60:	fb3c96e3          	bne	s9,s3,80004d0c <exec+0x1b6>
  sz = sz1;
    80004d64:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d68:	4481                	li	s1,0
    80004d6a:	a84d                	j	80004e1c <exec+0x2c6>
  sp = sz;
    80004d6c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d6e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d70:	00349793          	slli	a5,s1,0x3
    80004d74:	f9040713          	addi	a4,s0,-112
    80004d78:	97ba                	add	a5,a5,a4
    80004d7a:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004d7e:	00148693          	addi	a3,s1,1
    80004d82:	068e                	slli	a3,a3,0x3
    80004d84:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d88:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d8c:	01897663          	bgeu	s2,s8,80004d98 <exec+0x242>
  sz = sz1;
    80004d90:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d94:	4481                	li	s1,0
    80004d96:	a059                	j	80004e1c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d98:	e8840613          	addi	a2,s0,-376
    80004d9c:	85ca                	mv	a1,s2
    80004d9e:	855e                	mv	a0,s7
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	8b6080e7          	jalr	-1866(ra) # 80001656 <copyout>
    80004da8:	0a054663          	bltz	a0,80004e54 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004dac:	058ab783          	ld	a5,88(s5)
    80004db0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004db4:	df843783          	ld	a5,-520(s0)
    80004db8:	0007c703          	lbu	a4,0(a5)
    80004dbc:	cf11                	beqz	a4,80004dd8 <exec+0x282>
    80004dbe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dc0:	02f00693          	li	a3,47
    80004dc4:	a029                	j	80004dce <exec+0x278>
  for(last=s=path; *s; s++)
    80004dc6:	0785                	addi	a5,a5,1
    80004dc8:	fff7c703          	lbu	a4,-1(a5)
    80004dcc:	c711                	beqz	a4,80004dd8 <exec+0x282>
    if(*s == '/')
    80004dce:	fed71ce3          	bne	a4,a3,80004dc6 <exec+0x270>
      last = s+1;
    80004dd2:	def43c23          	sd	a5,-520(s0)
    80004dd6:	bfc5                	j	80004dc6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dd8:	4641                	li	a2,16
    80004dda:	df843583          	ld	a1,-520(s0)
    80004dde:	158a8513          	addi	a0,s5,344
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	046080e7          	jalr	70(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004dea:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004dee:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004df2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004df6:	058ab783          	ld	a5,88(s5)
    80004dfa:	e6043703          	ld	a4,-416(s0)
    80004dfe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e00:	058ab783          	ld	a5,88(s5)
    80004e04:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e08:	85ea                	mv	a1,s10
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	cea080e7          	jalr	-790(ra) # 80001af4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e12:	0004851b          	sext.w	a0,s1
    80004e16:	bbe1                	j	80004bee <exec+0x98>
    80004e18:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e1c:	e0843583          	ld	a1,-504(s0)
    80004e20:	855e                	mv	a0,s7
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	cd2080e7          	jalr	-814(ra) # 80001af4 <proc_freepagetable>
  if(ip){
    80004e2a:	da0498e3          	bnez	s1,80004bda <exec+0x84>
  return -1;
    80004e2e:	557d                	li	a0,-1
    80004e30:	bb7d                	j	80004bee <exec+0x98>
    80004e32:	e1243423          	sd	s2,-504(s0)
    80004e36:	b7dd                	j	80004e1c <exec+0x2c6>
    80004e38:	e1243423          	sd	s2,-504(s0)
    80004e3c:	b7c5                	j	80004e1c <exec+0x2c6>
    80004e3e:	e1243423          	sd	s2,-504(s0)
    80004e42:	bfe9                	j	80004e1c <exec+0x2c6>
  sz = sz1;
    80004e44:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e48:	4481                	li	s1,0
    80004e4a:	bfc9                	j	80004e1c <exec+0x2c6>
  sz = sz1;
    80004e4c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e50:	4481                	li	s1,0
    80004e52:	b7e9                	j	80004e1c <exec+0x2c6>
  sz = sz1;
    80004e54:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e58:	4481                	li	s1,0
    80004e5a:	b7c9                	j	80004e1c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e5c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e60:	2b05                	addiw	s6,s6,1
    80004e62:	0389899b          	addiw	s3,s3,56
    80004e66:	e8045783          	lhu	a5,-384(s0)
    80004e6a:	e2fb5be3          	bge	s6,a5,80004ca0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e6e:	2981                	sext.w	s3,s3
    80004e70:	03800713          	li	a4,56
    80004e74:	86ce                	mv	a3,s3
    80004e76:	e1040613          	addi	a2,s0,-496
    80004e7a:	4581                	li	a1,0
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	a8e080e7          	jalr	-1394(ra) # 8000390c <readi>
    80004e86:	03800793          	li	a5,56
    80004e8a:	f8f517e3          	bne	a0,a5,80004e18 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e8e:	e1042783          	lw	a5,-496(s0)
    80004e92:	4705                	li	a4,1
    80004e94:	fce796e3          	bne	a5,a4,80004e60 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e98:	e3843603          	ld	a2,-456(s0)
    80004e9c:	e3043783          	ld	a5,-464(s0)
    80004ea0:	f8f669e3          	bltu	a2,a5,80004e32 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ea4:	e2043783          	ld	a5,-480(s0)
    80004ea8:	963e                	add	a2,a2,a5
    80004eaa:	f8f667e3          	bltu	a2,a5,80004e38 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eae:	85ca                	mv	a1,s2
    80004eb0:	855e                	mv	a0,s7
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	554080e7          	jalr	1364(ra) # 80001406 <uvmalloc>
    80004eba:	e0a43423          	sd	a0,-504(s0)
    80004ebe:	d141                	beqz	a0,80004e3e <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004ec0:	e2043d03          	ld	s10,-480(s0)
    80004ec4:	df043783          	ld	a5,-528(s0)
    80004ec8:	00fd77b3          	and	a5,s10,a5
    80004ecc:	fba1                	bnez	a5,80004e1c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ece:	e1842d83          	lw	s11,-488(s0)
    80004ed2:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ed6:	f80c03e3          	beqz	s8,80004e5c <exec+0x306>
    80004eda:	8a62                	mv	s4,s8
    80004edc:	4901                	li	s2,0
    80004ede:	b345                	j	80004c7e <exec+0x128>

0000000080004ee0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ee0:	7179                	addi	sp,sp,-48
    80004ee2:	f406                	sd	ra,40(sp)
    80004ee4:	f022                	sd	s0,32(sp)
    80004ee6:	ec26                	sd	s1,24(sp)
    80004ee8:	e84a                	sd	s2,16(sp)
    80004eea:	1800                	addi	s0,sp,48
    80004eec:	892e                	mv	s2,a1
    80004eee:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ef0:	fdc40593          	addi	a1,s0,-36
    80004ef4:	ffffe097          	auipc	ra,0xffffe
    80004ef8:	ba8080e7          	jalr	-1112(ra) # 80002a9c <argint>
    80004efc:	04054063          	bltz	a0,80004f3c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f00:	fdc42703          	lw	a4,-36(s0)
    80004f04:	47bd                	li	a5,15
    80004f06:	02e7ed63          	bltu	a5,a4,80004f40 <argfd+0x60>
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	a8a080e7          	jalr	-1398(ra) # 80001994 <myproc>
    80004f12:	fdc42703          	lw	a4,-36(s0)
    80004f16:	01a70793          	addi	a5,a4,26
    80004f1a:	078e                	slli	a5,a5,0x3
    80004f1c:	953e                	add	a0,a0,a5
    80004f1e:	611c                	ld	a5,0(a0)
    80004f20:	c395                	beqz	a5,80004f44 <argfd+0x64>
    return -1;
  if(pfd)
    80004f22:	00090463          	beqz	s2,80004f2a <argfd+0x4a>
    *pfd = fd;
    80004f26:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f2a:	4501                	li	a0,0
  if(pf)
    80004f2c:	c091                	beqz	s1,80004f30 <argfd+0x50>
    *pf = f;
    80004f2e:	e09c                	sd	a5,0(s1)
}
    80004f30:	70a2                	ld	ra,40(sp)
    80004f32:	7402                	ld	s0,32(sp)
    80004f34:	64e2                	ld	s1,24(sp)
    80004f36:	6942                	ld	s2,16(sp)
    80004f38:	6145                	addi	sp,sp,48
    80004f3a:	8082                	ret
    return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	bfcd                	j	80004f30 <argfd+0x50>
    return -1;
    80004f40:	557d                	li	a0,-1
    80004f42:	b7fd                	j	80004f30 <argfd+0x50>
    80004f44:	557d                	li	a0,-1
    80004f46:	b7ed                	j	80004f30 <argfd+0x50>

0000000080004f48 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f48:	1101                	addi	sp,sp,-32
    80004f4a:	ec06                	sd	ra,24(sp)
    80004f4c:	e822                	sd	s0,16(sp)
    80004f4e:	e426                	sd	s1,8(sp)
    80004f50:	1000                	addi	s0,sp,32
    80004f52:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f54:	ffffd097          	auipc	ra,0xffffd
    80004f58:	a40080e7          	jalr	-1472(ra) # 80001994 <myproc>
    80004f5c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f5e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004f62:	4501                	li	a0,0
    80004f64:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f66:	6398                	ld	a4,0(a5)
    80004f68:	cb19                	beqz	a4,80004f7e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f6a:	2505                	addiw	a0,a0,1
    80004f6c:	07a1                	addi	a5,a5,8
    80004f6e:	fed51ce3          	bne	a0,a3,80004f66 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f72:	557d                	li	a0,-1
}
    80004f74:	60e2                	ld	ra,24(sp)
    80004f76:	6442                	ld	s0,16(sp)
    80004f78:	64a2                	ld	s1,8(sp)
    80004f7a:	6105                	addi	sp,sp,32
    80004f7c:	8082                	ret
      p->ofile[fd] = f;
    80004f7e:	01a50793          	addi	a5,a0,26
    80004f82:	078e                	slli	a5,a5,0x3
    80004f84:	963e                	add	a2,a2,a5
    80004f86:	e204                	sd	s1,0(a2)
      return fd;
    80004f88:	b7f5                	j	80004f74 <fdalloc+0x2c>

0000000080004f8a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f8a:	715d                	addi	sp,sp,-80
    80004f8c:	e486                	sd	ra,72(sp)
    80004f8e:	e0a2                	sd	s0,64(sp)
    80004f90:	fc26                	sd	s1,56(sp)
    80004f92:	f84a                	sd	s2,48(sp)
    80004f94:	f44e                	sd	s3,40(sp)
    80004f96:	f052                	sd	s4,32(sp)
    80004f98:	ec56                	sd	s5,24(sp)
    80004f9a:	0880                	addi	s0,sp,80
    80004f9c:	89ae                	mv	s3,a1
    80004f9e:	8ab2                	mv	s5,a2
    80004fa0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fa2:	fb040593          	addi	a1,s0,-80
    80004fa6:	fffff097          	auipc	ra,0xfffff
    80004faa:	e86080e7          	jalr	-378(ra) # 80003e2c <nameiparent>
    80004fae:	892a                	mv	s2,a0
    80004fb0:	12050f63          	beqz	a0,800050ee <create+0x164>
    return 0;

  ilock(dp);
    80004fb4:	ffffe097          	auipc	ra,0xffffe
    80004fb8:	6a4080e7          	jalr	1700(ra) # 80003658 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fbc:	4601                	li	a2,0
    80004fbe:	fb040593          	addi	a1,s0,-80
    80004fc2:	854a                	mv	a0,s2
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	b78080e7          	jalr	-1160(ra) # 80003b3c <dirlookup>
    80004fcc:	84aa                	mv	s1,a0
    80004fce:	c921                	beqz	a0,8000501e <create+0x94>
    iunlockput(dp);
    80004fd0:	854a                	mv	a0,s2
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	8e8080e7          	jalr	-1816(ra) # 800038ba <iunlockput>
    ilock(ip);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	ffffe097          	auipc	ra,0xffffe
    80004fe0:	67c080e7          	jalr	1660(ra) # 80003658 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fe4:	2981                	sext.w	s3,s3
    80004fe6:	4789                	li	a5,2
    80004fe8:	02f99463          	bne	s3,a5,80005010 <create+0x86>
    80004fec:	0444d783          	lhu	a5,68(s1)
    80004ff0:	37f9                	addiw	a5,a5,-2
    80004ff2:	17c2                	slli	a5,a5,0x30
    80004ff4:	93c1                	srli	a5,a5,0x30
    80004ff6:	4705                	li	a4,1
    80004ff8:	00f76c63          	bltu	a4,a5,80005010 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004ffc:	8526                	mv	a0,s1
    80004ffe:	60a6                	ld	ra,72(sp)
    80005000:	6406                	ld	s0,64(sp)
    80005002:	74e2                	ld	s1,56(sp)
    80005004:	7942                	ld	s2,48(sp)
    80005006:	79a2                	ld	s3,40(sp)
    80005008:	7a02                	ld	s4,32(sp)
    8000500a:	6ae2                	ld	s5,24(sp)
    8000500c:	6161                	addi	sp,sp,80
    8000500e:	8082                	ret
    iunlockput(ip);
    80005010:	8526                	mv	a0,s1
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	8a8080e7          	jalr	-1880(ra) # 800038ba <iunlockput>
    return 0;
    8000501a:	4481                	li	s1,0
    8000501c:	b7c5                	j	80004ffc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000501e:	85ce                	mv	a1,s3
    80005020:	00092503          	lw	a0,0(s2)
    80005024:	ffffe097          	auipc	ra,0xffffe
    80005028:	49c080e7          	jalr	1180(ra) # 800034c0 <ialloc>
    8000502c:	84aa                	mv	s1,a0
    8000502e:	c529                	beqz	a0,80005078 <create+0xee>
  ilock(ip);
    80005030:	ffffe097          	auipc	ra,0xffffe
    80005034:	628080e7          	jalr	1576(ra) # 80003658 <ilock>
  ip->major = major;
    80005038:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000503c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005040:	4785                	li	a5,1
    80005042:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005046:	8526                	mv	a0,s1
    80005048:	ffffe097          	auipc	ra,0xffffe
    8000504c:	546080e7          	jalr	1350(ra) # 8000358e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005050:	2981                	sext.w	s3,s3
    80005052:	4785                	li	a5,1
    80005054:	02f98a63          	beq	s3,a5,80005088 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005058:	40d0                	lw	a2,4(s1)
    8000505a:	fb040593          	addi	a1,s0,-80
    8000505e:	854a                	mv	a0,s2
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	cec080e7          	jalr	-788(ra) # 80003d4c <dirlink>
    80005068:	06054b63          	bltz	a0,800050de <create+0x154>
  iunlockput(dp);
    8000506c:	854a                	mv	a0,s2
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	84c080e7          	jalr	-1972(ra) # 800038ba <iunlockput>
  return ip;
    80005076:	b759                	j	80004ffc <create+0x72>
    panic("create: ialloc");
    80005078:	00003517          	auipc	a0,0x3
    8000507c:	66850513          	addi	a0,a0,1640 # 800086e0 <syscalls+0x2b0>
    80005080:	ffffb097          	auipc	ra,0xffffb
    80005084:	4b0080e7          	jalr	1200(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005088:	04a95783          	lhu	a5,74(s2)
    8000508c:	2785                	addiw	a5,a5,1
    8000508e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005092:	854a                	mv	a0,s2
    80005094:	ffffe097          	auipc	ra,0xffffe
    80005098:	4fa080e7          	jalr	1274(ra) # 8000358e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000509c:	40d0                	lw	a2,4(s1)
    8000509e:	00003597          	auipc	a1,0x3
    800050a2:	65258593          	addi	a1,a1,1618 # 800086f0 <syscalls+0x2c0>
    800050a6:	8526                	mv	a0,s1
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	ca4080e7          	jalr	-860(ra) # 80003d4c <dirlink>
    800050b0:	00054f63          	bltz	a0,800050ce <create+0x144>
    800050b4:	00492603          	lw	a2,4(s2)
    800050b8:	00003597          	auipc	a1,0x3
    800050bc:	64058593          	addi	a1,a1,1600 # 800086f8 <syscalls+0x2c8>
    800050c0:	8526                	mv	a0,s1
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	c8a080e7          	jalr	-886(ra) # 80003d4c <dirlink>
    800050ca:	f80557e3          	bgez	a0,80005058 <create+0xce>
      panic("create dots");
    800050ce:	00003517          	auipc	a0,0x3
    800050d2:	63250513          	addi	a0,a0,1586 # 80008700 <syscalls+0x2d0>
    800050d6:	ffffb097          	auipc	ra,0xffffb
    800050da:	45a080e7          	jalr	1114(ra) # 80000530 <panic>
    panic("create: dirlink");
    800050de:	00003517          	auipc	a0,0x3
    800050e2:	63250513          	addi	a0,a0,1586 # 80008710 <syscalls+0x2e0>
    800050e6:	ffffb097          	auipc	ra,0xffffb
    800050ea:	44a080e7          	jalr	1098(ra) # 80000530 <panic>
    return 0;
    800050ee:	84aa                	mv	s1,a0
    800050f0:	b731                	j	80004ffc <create+0x72>

00000000800050f2 <sys_dup>:
{
    800050f2:	7179                	addi	sp,sp,-48
    800050f4:	f406                	sd	ra,40(sp)
    800050f6:	f022                	sd	s0,32(sp)
    800050f8:	ec26                	sd	s1,24(sp)
    800050fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050fc:	fd840613          	addi	a2,s0,-40
    80005100:	4581                	li	a1,0
    80005102:	4501                	li	a0,0
    80005104:	00000097          	auipc	ra,0x0
    80005108:	ddc080e7          	jalr	-548(ra) # 80004ee0 <argfd>
    return -1;
    8000510c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000510e:	02054363          	bltz	a0,80005134 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005112:	fd843503          	ld	a0,-40(s0)
    80005116:	00000097          	auipc	ra,0x0
    8000511a:	e32080e7          	jalr	-462(ra) # 80004f48 <fdalloc>
    8000511e:	84aa                	mv	s1,a0
    return -1;
    80005120:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005122:	00054963          	bltz	a0,80005134 <sys_dup+0x42>
  filedup(f);
    80005126:	fd843503          	ld	a0,-40(s0)
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	37a080e7          	jalr	890(ra) # 800044a4 <filedup>
  return fd;
    80005132:	87a6                	mv	a5,s1
}
    80005134:	853e                	mv	a0,a5
    80005136:	70a2                	ld	ra,40(sp)
    80005138:	7402                	ld	s0,32(sp)
    8000513a:	64e2                	ld	s1,24(sp)
    8000513c:	6145                	addi	sp,sp,48
    8000513e:	8082                	ret

0000000080005140 <sys_read>:
{
    80005140:	7179                	addi	sp,sp,-48
    80005142:	f406                	sd	ra,40(sp)
    80005144:	f022                	sd	s0,32(sp)
    80005146:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005148:	fe840613          	addi	a2,s0,-24
    8000514c:	4581                	li	a1,0
    8000514e:	4501                	li	a0,0
    80005150:	00000097          	auipc	ra,0x0
    80005154:	d90080e7          	jalr	-624(ra) # 80004ee0 <argfd>
    return -1;
    80005158:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515a:	04054163          	bltz	a0,8000519c <sys_read+0x5c>
    8000515e:	fe440593          	addi	a1,s0,-28
    80005162:	4509                	li	a0,2
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	938080e7          	jalr	-1736(ra) # 80002a9c <argint>
    return -1;
    8000516c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000516e:	02054763          	bltz	a0,8000519c <sys_read+0x5c>
    80005172:	fd840593          	addi	a1,s0,-40
    80005176:	4505                	li	a0,1
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	946080e7          	jalr	-1722(ra) # 80002abe <argaddr>
    return -1;
    80005180:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005182:	00054d63          	bltz	a0,8000519c <sys_read+0x5c>
  return fileread(f, p, n);
    80005186:	fe442603          	lw	a2,-28(s0)
    8000518a:	fd843583          	ld	a1,-40(s0)
    8000518e:	fe843503          	ld	a0,-24(s0)
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	49e080e7          	jalr	1182(ra) # 80004630 <fileread>
    8000519a:	87aa                	mv	a5,a0
}
    8000519c:	853e                	mv	a0,a5
    8000519e:	70a2                	ld	ra,40(sp)
    800051a0:	7402                	ld	s0,32(sp)
    800051a2:	6145                	addi	sp,sp,48
    800051a4:	8082                	ret

00000000800051a6 <sys_write>:
{
    800051a6:	7179                	addi	sp,sp,-48
    800051a8:	f406                	sd	ra,40(sp)
    800051aa:	f022                	sd	s0,32(sp)
    800051ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ae:	fe840613          	addi	a2,s0,-24
    800051b2:	4581                	li	a1,0
    800051b4:	4501                	li	a0,0
    800051b6:	00000097          	auipc	ra,0x0
    800051ba:	d2a080e7          	jalr	-726(ra) # 80004ee0 <argfd>
    return -1;
    800051be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c0:	04054163          	bltz	a0,80005202 <sys_write+0x5c>
    800051c4:	fe440593          	addi	a1,s0,-28
    800051c8:	4509                	li	a0,2
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	8d2080e7          	jalr	-1838(ra) # 80002a9c <argint>
    return -1;
    800051d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d4:	02054763          	bltz	a0,80005202 <sys_write+0x5c>
    800051d8:	fd840593          	addi	a1,s0,-40
    800051dc:	4505                	li	a0,1
    800051de:	ffffe097          	auipc	ra,0xffffe
    800051e2:	8e0080e7          	jalr	-1824(ra) # 80002abe <argaddr>
    return -1;
    800051e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e8:	00054d63          	bltz	a0,80005202 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051ec:	fe442603          	lw	a2,-28(s0)
    800051f0:	fd843583          	ld	a1,-40(s0)
    800051f4:	fe843503          	ld	a0,-24(s0)
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	4fa080e7          	jalr	1274(ra) # 800046f2 <filewrite>
    80005200:	87aa                	mv	a5,a0
}
    80005202:	853e                	mv	a0,a5
    80005204:	70a2                	ld	ra,40(sp)
    80005206:	7402                	ld	s0,32(sp)
    80005208:	6145                	addi	sp,sp,48
    8000520a:	8082                	ret

000000008000520c <sys_close>:
{
    8000520c:	1101                	addi	sp,sp,-32
    8000520e:	ec06                	sd	ra,24(sp)
    80005210:	e822                	sd	s0,16(sp)
    80005212:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005214:	fe040613          	addi	a2,s0,-32
    80005218:	fec40593          	addi	a1,s0,-20
    8000521c:	4501                	li	a0,0
    8000521e:	00000097          	auipc	ra,0x0
    80005222:	cc2080e7          	jalr	-830(ra) # 80004ee0 <argfd>
    return -1;
    80005226:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005228:	02054463          	bltz	a0,80005250 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	768080e7          	jalr	1896(ra) # 80001994 <myproc>
    80005234:	fec42783          	lw	a5,-20(s0)
    80005238:	07e9                	addi	a5,a5,26
    8000523a:	078e                	slli	a5,a5,0x3
    8000523c:	97aa                	add	a5,a5,a0
    8000523e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005242:	fe043503          	ld	a0,-32(s0)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	2b0080e7          	jalr	688(ra) # 800044f6 <fileclose>
  return 0;
    8000524e:	4781                	li	a5,0
}
    80005250:	853e                	mv	a0,a5
    80005252:	60e2                	ld	ra,24(sp)
    80005254:	6442                	ld	s0,16(sp)
    80005256:	6105                	addi	sp,sp,32
    80005258:	8082                	ret

000000008000525a <sys_fstat>:
{
    8000525a:	1101                	addi	sp,sp,-32
    8000525c:	ec06                	sd	ra,24(sp)
    8000525e:	e822                	sd	s0,16(sp)
    80005260:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005262:	fe840613          	addi	a2,s0,-24
    80005266:	4581                	li	a1,0
    80005268:	4501                	li	a0,0
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	c76080e7          	jalr	-906(ra) # 80004ee0 <argfd>
    return -1;
    80005272:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005274:	02054563          	bltz	a0,8000529e <sys_fstat+0x44>
    80005278:	fe040593          	addi	a1,s0,-32
    8000527c:	4505                	li	a0,1
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	840080e7          	jalr	-1984(ra) # 80002abe <argaddr>
    return -1;
    80005286:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005288:	00054b63          	bltz	a0,8000529e <sys_fstat+0x44>
  return filestat(f, st);
    8000528c:	fe043583          	ld	a1,-32(s0)
    80005290:	fe843503          	ld	a0,-24(s0)
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	32a080e7          	jalr	810(ra) # 800045be <filestat>
    8000529c:	87aa                	mv	a5,a0
}
    8000529e:	853e                	mv	a0,a5
    800052a0:	60e2                	ld	ra,24(sp)
    800052a2:	6442                	ld	s0,16(sp)
    800052a4:	6105                	addi	sp,sp,32
    800052a6:	8082                	ret

00000000800052a8 <sys_link>:
{
    800052a8:	7169                	addi	sp,sp,-304
    800052aa:	f606                	sd	ra,296(sp)
    800052ac:	f222                	sd	s0,288(sp)
    800052ae:	ee26                	sd	s1,280(sp)
    800052b0:	ea4a                	sd	s2,272(sp)
    800052b2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052b4:	08000613          	li	a2,128
    800052b8:	ed040593          	addi	a1,s0,-304
    800052bc:	4501                	li	a0,0
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	822080e7          	jalr	-2014(ra) # 80002ae0 <argstr>
    return -1;
    800052c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052c8:	10054e63          	bltz	a0,800053e4 <sys_link+0x13c>
    800052cc:	08000613          	li	a2,128
    800052d0:	f5040593          	addi	a1,s0,-176
    800052d4:	4505                	li	a0,1
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	80a080e7          	jalr	-2038(ra) # 80002ae0 <argstr>
    return -1;
    800052de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052e0:	10054263          	bltz	a0,800053e4 <sys_link+0x13c>
  begin_op();
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	d46080e7          	jalr	-698(ra) # 8000402a <begin_op>
  if((ip = namei(old)) == 0){
    800052ec:	ed040513          	addi	a0,s0,-304
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	b1e080e7          	jalr	-1250(ra) # 80003e0e <namei>
    800052f8:	84aa                	mv	s1,a0
    800052fa:	c551                	beqz	a0,80005386 <sys_link+0xde>
  ilock(ip);
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	35c080e7          	jalr	860(ra) # 80003658 <ilock>
  if(ip->type == T_DIR){
    80005304:	04449703          	lh	a4,68(s1)
    80005308:	4785                	li	a5,1
    8000530a:	08f70463          	beq	a4,a5,80005392 <sys_link+0xea>
  ip->nlink++;
    8000530e:	04a4d783          	lhu	a5,74(s1)
    80005312:	2785                	addiw	a5,a5,1
    80005314:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005318:	8526                	mv	a0,s1
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	274080e7          	jalr	628(ra) # 8000358e <iupdate>
  iunlock(ip);
    80005322:	8526                	mv	a0,s1
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	3f6080e7          	jalr	1014(ra) # 8000371a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000532c:	fd040593          	addi	a1,s0,-48
    80005330:	f5040513          	addi	a0,s0,-176
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	af8080e7          	jalr	-1288(ra) # 80003e2c <nameiparent>
    8000533c:	892a                	mv	s2,a0
    8000533e:	c935                	beqz	a0,800053b2 <sys_link+0x10a>
  ilock(dp);
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	318080e7          	jalr	792(ra) # 80003658 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005348:	00092703          	lw	a4,0(s2)
    8000534c:	409c                	lw	a5,0(s1)
    8000534e:	04f71d63          	bne	a4,a5,800053a8 <sys_link+0x100>
    80005352:	40d0                	lw	a2,4(s1)
    80005354:	fd040593          	addi	a1,s0,-48
    80005358:	854a                	mv	a0,s2
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	9f2080e7          	jalr	-1550(ra) # 80003d4c <dirlink>
    80005362:	04054363          	bltz	a0,800053a8 <sys_link+0x100>
  iunlockput(dp);
    80005366:	854a                	mv	a0,s2
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	552080e7          	jalr	1362(ra) # 800038ba <iunlockput>
  iput(ip);
    80005370:	8526                	mv	a0,s1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	4a0080e7          	jalr	1184(ra) # 80003812 <iput>
  end_op();
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	d30080e7          	jalr	-720(ra) # 800040aa <end_op>
  return 0;
    80005382:	4781                	li	a5,0
    80005384:	a085                	j	800053e4 <sys_link+0x13c>
    end_op();
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	d24080e7          	jalr	-732(ra) # 800040aa <end_op>
    return -1;
    8000538e:	57fd                	li	a5,-1
    80005390:	a891                	j	800053e4 <sys_link+0x13c>
    iunlockput(ip);
    80005392:	8526                	mv	a0,s1
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	526080e7          	jalr	1318(ra) # 800038ba <iunlockput>
    end_op();
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	d0e080e7          	jalr	-754(ra) # 800040aa <end_op>
    return -1;
    800053a4:	57fd                	li	a5,-1
    800053a6:	a83d                	j	800053e4 <sys_link+0x13c>
    iunlockput(dp);
    800053a8:	854a                	mv	a0,s2
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	510080e7          	jalr	1296(ra) # 800038ba <iunlockput>
  ilock(ip);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	2a4080e7          	jalr	676(ra) # 80003658 <ilock>
  ip->nlink--;
    800053bc:	04a4d783          	lhu	a5,74(s1)
    800053c0:	37fd                	addiw	a5,a5,-1
    800053c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	1c6080e7          	jalr	454(ra) # 8000358e <iupdate>
  iunlockput(ip);
    800053d0:	8526                	mv	a0,s1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	4e8080e7          	jalr	1256(ra) # 800038ba <iunlockput>
  end_op();
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	cd0080e7          	jalr	-816(ra) # 800040aa <end_op>
  return -1;
    800053e2:	57fd                	li	a5,-1
}
    800053e4:	853e                	mv	a0,a5
    800053e6:	70b2                	ld	ra,296(sp)
    800053e8:	7412                	ld	s0,288(sp)
    800053ea:	64f2                	ld	s1,280(sp)
    800053ec:	6952                	ld	s2,272(sp)
    800053ee:	6155                	addi	sp,sp,304
    800053f0:	8082                	ret

00000000800053f2 <sys_unlink>:
{
    800053f2:	7151                	addi	sp,sp,-240
    800053f4:	f586                	sd	ra,232(sp)
    800053f6:	f1a2                	sd	s0,224(sp)
    800053f8:	eda6                	sd	s1,216(sp)
    800053fa:	e9ca                	sd	s2,208(sp)
    800053fc:	e5ce                	sd	s3,200(sp)
    800053fe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005400:	08000613          	li	a2,128
    80005404:	f3040593          	addi	a1,s0,-208
    80005408:	4501                	li	a0,0
    8000540a:	ffffd097          	auipc	ra,0xffffd
    8000540e:	6d6080e7          	jalr	1750(ra) # 80002ae0 <argstr>
    80005412:	18054163          	bltz	a0,80005594 <sys_unlink+0x1a2>
  begin_op();
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	c14080e7          	jalr	-1004(ra) # 8000402a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000541e:	fb040593          	addi	a1,s0,-80
    80005422:	f3040513          	addi	a0,s0,-208
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	a06080e7          	jalr	-1530(ra) # 80003e2c <nameiparent>
    8000542e:	84aa                	mv	s1,a0
    80005430:	c979                	beqz	a0,80005506 <sys_unlink+0x114>
  ilock(dp);
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	226080e7          	jalr	550(ra) # 80003658 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000543a:	00003597          	auipc	a1,0x3
    8000543e:	2b658593          	addi	a1,a1,694 # 800086f0 <syscalls+0x2c0>
    80005442:	fb040513          	addi	a0,s0,-80
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	6dc080e7          	jalr	1756(ra) # 80003b22 <namecmp>
    8000544e:	14050a63          	beqz	a0,800055a2 <sys_unlink+0x1b0>
    80005452:	00003597          	auipc	a1,0x3
    80005456:	2a658593          	addi	a1,a1,678 # 800086f8 <syscalls+0x2c8>
    8000545a:	fb040513          	addi	a0,s0,-80
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	6c4080e7          	jalr	1732(ra) # 80003b22 <namecmp>
    80005466:	12050e63          	beqz	a0,800055a2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000546a:	f2c40613          	addi	a2,s0,-212
    8000546e:	fb040593          	addi	a1,s0,-80
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	6c8080e7          	jalr	1736(ra) # 80003b3c <dirlookup>
    8000547c:	892a                	mv	s2,a0
    8000547e:	12050263          	beqz	a0,800055a2 <sys_unlink+0x1b0>
  ilock(ip);
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	1d6080e7          	jalr	470(ra) # 80003658 <ilock>
  if(ip->nlink < 1)
    8000548a:	04a91783          	lh	a5,74(s2)
    8000548e:	08f05263          	blez	a5,80005512 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005492:	04491703          	lh	a4,68(s2)
    80005496:	4785                	li	a5,1
    80005498:	08f70563          	beq	a4,a5,80005522 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000549c:	4641                	li	a2,16
    8000549e:	4581                	li	a1,0
    800054a0:	fc040513          	addi	a0,s0,-64
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	82e080e7          	jalr	-2002(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ac:	4741                	li	a4,16
    800054ae:	f2c42683          	lw	a3,-212(s0)
    800054b2:	fc040613          	addi	a2,s0,-64
    800054b6:	4581                	li	a1,0
    800054b8:	8526                	mv	a0,s1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	54a080e7          	jalr	1354(ra) # 80003a04 <writei>
    800054c2:	47c1                	li	a5,16
    800054c4:	0af51563          	bne	a0,a5,8000556e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054c8:	04491703          	lh	a4,68(s2)
    800054cc:	4785                	li	a5,1
    800054ce:	0af70863          	beq	a4,a5,8000557e <sys_unlink+0x18c>
  iunlockput(dp);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	3e6080e7          	jalr	998(ra) # 800038ba <iunlockput>
  ip->nlink--;
    800054dc:	04a95783          	lhu	a5,74(s2)
    800054e0:	37fd                	addiw	a5,a5,-1
    800054e2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054e6:	854a                	mv	a0,s2
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	0a6080e7          	jalr	166(ra) # 8000358e <iupdate>
  iunlockput(ip);
    800054f0:	854a                	mv	a0,s2
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	3c8080e7          	jalr	968(ra) # 800038ba <iunlockput>
  end_op();
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	bb0080e7          	jalr	-1104(ra) # 800040aa <end_op>
  return 0;
    80005502:	4501                	li	a0,0
    80005504:	a84d                	j	800055b6 <sys_unlink+0x1c4>
    end_op();
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	ba4080e7          	jalr	-1116(ra) # 800040aa <end_op>
    return -1;
    8000550e:	557d                	li	a0,-1
    80005510:	a05d                	j	800055b6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005512:	00003517          	auipc	a0,0x3
    80005516:	20e50513          	addi	a0,a0,526 # 80008720 <syscalls+0x2f0>
    8000551a:	ffffb097          	auipc	ra,0xffffb
    8000551e:	016080e7          	jalr	22(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005522:	04c92703          	lw	a4,76(s2)
    80005526:	02000793          	li	a5,32
    8000552a:	f6e7f9e3          	bgeu	a5,a4,8000549c <sys_unlink+0xaa>
    8000552e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005532:	4741                	li	a4,16
    80005534:	86ce                	mv	a3,s3
    80005536:	f1840613          	addi	a2,s0,-232
    8000553a:	4581                	li	a1,0
    8000553c:	854a                	mv	a0,s2
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	3ce080e7          	jalr	974(ra) # 8000390c <readi>
    80005546:	47c1                	li	a5,16
    80005548:	00f51b63          	bne	a0,a5,8000555e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000554c:	f1845783          	lhu	a5,-232(s0)
    80005550:	e7a1                	bnez	a5,80005598 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005552:	29c1                	addiw	s3,s3,16
    80005554:	04c92783          	lw	a5,76(s2)
    80005558:	fcf9ede3          	bltu	s3,a5,80005532 <sys_unlink+0x140>
    8000555c:	b781                	j	8000549c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000555e:	00003517          	auipc	a0,0x3
    80005562:	1da50513          	addi	a0,a0,474 # 80008738 <syscalls+0x308>
    80005566:	ffffb097          	auipc	ra,0xffffb
    8000556a:	fca080e7          	jalr	-54(ra) # 80000530 <panic>
    panic("unlink: writei");
    8000556e:	00003517          	auipc	a0,0x3
    80005572:	1e250513          	addi	a0,a0,482 # 80008750 <syscalls+0x320>
    80005576:	ffffb097          	auipc	ra,0xffffb
    8000557a:	fba080e7          	jalr	-70(ra) # 80000530 <panic>
    dp->nlink--;
    8000557e:	04a4d783          	lhu	a5,74(s1)
    80005582:	37fd                	addiw	a5,a5,-1
    80005584:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	004080e7          	jalr	4(ra) # 8000358e <iupdate>
    80005592:	b781                	j	800054d2 <sys_unlink+0xe0>
    return -1;
    80005594:	557d                	li	a0,-1
    80005596:	a005                	j	800055b6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005598:	854a                	mv	a0,s2
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	320080e7          	jalr	800(ra) # 800038ba <iunlockput>
  iunlockput(dp);
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	316080e7          	jalr	790(ra) # 800038ba <iunlockput>
  end_op();
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	afe080e7          	jalr	-1282(ra) # 800040aa <end_op>
  return -1;
    800055b4:	557d                	li	a0,-1
}
    800055b6:	70ae                	ld	ra,232(sp)
    800055b8:	740e                	ld	s0,224(sp)
    800055ba:	64ee                	ld	s1,216(sp)
    800055bc:	694e                	ld	s2,208(sp)
    800055be:	69ae                	ld	s3,200(sp)
    800055c0:	616d                	addi	sp,sp,240
    800055c2:	8082                	ret

00000000800055c4 <sys_open>:

uint64
sys_open(void)
{
    800055c4:	7131                	addi	sp,sp,-192
    800055c6:	fd06                	sd	ra,184(sp)
    800055c8:	f922                	sd	s0,176(sp)
    800055ca:	f526                	sd	s1,168(sp)
    800055cc:	f14a                	sd	s2,160(sp)
    800055ce:	ed4e                	sd	s3,152(sp)
    800055d0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055d2:	08000613          	li	a2,128
    800055d6:	f5040593          	addi	a1,s0,-176
    800055da:	4501                	li	a0,0
    800055dc:	ffffd097          	auipc	ra,0xffffd
    800055e0:	504080e7          	jalr	1284(ra) # 80002ae0 <argstr>
    return -1;
    800055e4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055e6:	0c054163          	bltz	a0,800056a8 <sys_open+0xe4>
    800055ea:	f4c40593          	addi	a1,s0,-180
    800055ee:	4505                	li	a0,1
    800055f0:	ffffd097          	auipc	ra,0xffffd
    800055f4:	4ac080e7          	jalr	1196(ra) # 80002a9c <argint>
    800055f8:	0a054863          	bltz	a0,800056a8 <sys_open+0xe4>

  begin_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	a2e080e7          	jalr	-1490(ra) # 8000402a <begin_op>

  if(omode & O_CREATE){
    80005604:	f4c42783          	lw	a5,-180(s0)
    80005608:	2007f793          	andi	a5,a5,512
    8000560c:	cbdd                	beqz	a5,800056c2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000560e:	4681                	li	a3,0
    80005610:	4601                	li	a2,0
    80005612:	4589                	li	a1,2
    80005614:	f5040513          	addi	a0,s0,-176
    80005618:	00000097          	auipc	ra,0x0
    8000561c:	972080e7          	jalr	-1678(ra) # 80004f8a <create>
    80005620:	892a                	mv	s2,a0
    if(ip == 0){
    80005622:	c959                	beqz	a0,800056b8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005624:	04491703          	lh	a4,68(s2)
    80005628:	478d                	li	a5,3
    8000562a:	00f71763          	bne	a4,a5,80005638 <sys_open+0x74>
    8000562e:	04695703          	lhu	a4,70(s2)
    80005632:	47a5                	li	a5,9
    80005634:	0ce7ec63          	bltu	a5,a4,8000570c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	e02080e7          	jalr	-510(ra) # 8000443a <filealloc>
    80005640:	89aa                	mv	s3,a0
    80005642:	10050263          	beqz	a0,80005746 <sys_open+0x182>
    80005646:	00000097          	auipc	ra,0x0
    8000564a:	902080e7          	jalr	-1790(ra) # 80004f48 <fdalloc>
    8000564e:	84aa                	mv	s1,a0
    80005650:	0e054663          	bltz	a0,8000573c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005654:	04491703          	lh	a4,68(s2)
    80005658:	478d                	li	a5,3
    8000565a:	0cf70463          	beq	a4,a5,80005722 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000565e:	4789                	li	a5,2
    80005660:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005664:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005668:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000566c:	f4c42783          	lw	a5,-180(s0)
    80005670:	0017c713          	xori	a4,a5,1
    80005674:	8b05                	andi	a4,a4,1
    80005676:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000567a:	0037f713          	andi	a4,a5,3
    8000567e:	00e03733          	snez	a4,a4
    80005682:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005686:	4007f793          	andi	a5,a5,1024
    8000568a:	c791                	beqz	a5,80005696 <sys_open+0xd2>
    8000568c:	04491703          	lh	a4,68(s2)
    80005690:	4789                	li	a5,2
    80005692:	08f70f63          	beq	a4,a5,80005730 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005696:	854a                	mv	a0,s2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	082080e7          	jalr	130(ra) # 8000371a <iunlock>
  end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	a0a080e7          	jalr	-1526(ra) # 800040aa <end_op>

  return fd;
}
    800056a8:	8526                	mv	a0,s1
    800056aa:	70ea                	ld	ra,184(sp)
    800056ac:	744a                	ld	s0,176(sp)
    800056ae:	74aa                	ld	s1,168(sp)
    800056b0:	790a                	ld	s2,160(sp)
    800056b2:	69ea                	ld	s3,152(sp)
    800056b4:	6129                	addi	sp,sp,192
    800056b6:	8082                	ret
      end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	9f2080e7          	jalr	-1550(ra) # 800040aa <end_op>
      return -1;
    800056c0:	b7e5                	j	800056a8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056c2:	f5040513          	addi	a0,s0,-176
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	748080e7          	jalr	1864(ra) # 80003e0e <namei>
    800056ce:	892a                	mv	s2,a0
    800056d0:	c905                	beqz	a0,80005700 <sys_open+0x13c>
    ilock(ip);
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	f86080e7          	jalr	-122(ra) # 80003658 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056da:	04491703          	lh	a4,68(s2)
    800056de:	4785                	li	a5,1
    800056e0:	f4f712e3          	bne	a4,a5,80005624 <sys_open+0x60>
    800056e4:	f4c42783          	lw	a5,-180(s0)
    800056e8:	dba1                	beqz	a5,80005638 <sys_open+0x74>
      iunlockput(ip);
    800056ea:	854a                	mv	a0,s2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	1ce080e7          	jalr	462(ra) # 800038ba <iunlockput>
      end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	9b6080e7          	jalr	-1610(ra) # 800040aa <end_op>
      return -1;
    800056fc:	54fd                	li	s1,-1
    800056fe:	b76d                	j	800056a8 <sys_open+0xe4>
      end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	9aa080e7          	jalr	-1622(ra) # 800040aa <end_op>
      return -1;
    80005708:	54fd                	li	s1,-1
    8000570a:	bf79                	j	800056a8 <sys_open+0xe4>
    iunlockput(ip);
    8000570c:	854a                	mv	a0,s2
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	1ac080e7          	jalr	428(ra) # 800038ba <iunlockput>
    end_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	994080e7          	jalr	-1644(ra) # 800040aa <end_op>
    return -1;
    8000571e:	54fd                	li	s1,-1
    80005720:	b761                	j	800056a8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005722:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005726:	04691783          	lh	a5,70(s2)
    8000572a:	02f99223          	sh	a5,36(s3)
    8000572e:	bf2d                	j	80005668 <sys_open+0xa4>
    itrunc(ip);
    80005730:	854a                	mv	a0,s2
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	034080e7          	jalr	52(ra) # 80003766 <itrunc>
    8000573a:	bfb1                	j	80005696 <sys_open+0xd2>
      fileclose(f);
    8000573c:	854e                	mv	a0,s3
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	db8080e7          	jalr	-584(ra) # 800044f6 <fileclose>
    iunlockput(ip);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	172080e7          	jalr	370(ra) # 800038ba <iunlockput>
    end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	95a080e7          	jalr	-1702(ra) # 800040aa <end_op>
    return -1;
    80005758:	54fd                	li	s1,-1
    8000575a:	b7b9                	j	800056a8 <sys_open+0xe4>

000000008000575c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000575c:	7175                	addi	sp,sp,-144
    8000575e:	e506                	sd	ra,136(sp)
    80005760:	e122                	sd	s0,128(sp)
    80005762:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	8c6080e7          	jalr	-1850(ra) # 8000402a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000576c:	08000613          	li	a2,128
    80005770:	f7040593          	addi	a1,s0,-144
    80005774:	4501                	li	a0,0
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	36a080e7          	jalr	874(ra) # 80002ae0 <argstr>
    8000577e:	02054963          	bltz	a0,800057b0 <sys_mkdir+0x54>
    80005782:	4681                	li	a3,0
    80005784:	4601                	li	a2,0
    80005786:	4585                	li	a1,1
    80005788:	f7040513          	addi	a0,s0,-144
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	7fe080e7          	jalr	2046(ra) # 80004f8a <create>
    80005794:	cd11                	beqz	a0,800057b0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	124080e7          	jalr	292(ra) # 800038ba <iunlockput>
  end_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	90c080e7          	jalr	-1780(ra) # 800040aa <end_op>
  return 0;
    800057a6:	4501                	li	a0,0
}
    800057a8:	60aa                	ld	ra,136(sp)
    800057aa:	640a                	ld	s0,128(sp)
    800057ac:	6149                	addi	sp,sp,144
    800057ae:	8082                	ret
    end_op();
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	8fa080e7          	jalr	-1798(ra) # 800040aa <end_op>
    return -1;
    800057b8:	557d                	li	a0,-1
    800057ba:	b7fd                	j	800057a8 <sys_mkdir+0x4c>

00000000800057bc <sys_mknod>:

uint64
sys_mknod(void)
{
    800057bc:	7135                	addi	sp,sp,-160
    800057be:	ed06                	sd	ra,152(sp)
    800057c0:	e922                	sd	s0,144(sp)
    800057c2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	866080e7          	jalr	-1946(ra) # 8000402a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057cc:	08000613          	li	a2,128
    800057d0:	f7040593          	addi	a1,s0,-144
    800057d4:	4501                	li	a0,0
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	30a080e7          	jalr	778(ra) # 80002ae0 <argstr>
    800057de:	04054a63          	bltz	a0,80005832 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057e2:	f6c40593          	addi	a1,s0,-148
    800057e6:	4505                	li	a0,1
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	2b4080e7          	jalr	692(ra) # 80002a9c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057f0:	04054163          	bltz	a0,80005832 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057f4:	f6840593          	addi	a1,s0,-152
    800057f8:	4509                	li	a0,2
    800057fa:	ffffd097          	auipc	ra,0xffffd
    800057fe:	2a2080e7          	jalr	674(ra) # 80002a9c <argint>
     argint(1, &major) < 0 ||
    80005802:	02054863          	bltz	a0,80005832 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005806:	f6841683          	lh	a3,-152(s0)
    8000580a:	f6c41603          	lh	a2,-148(s0)
    8000580e:	458d                	li	a1,3
    80005810:	f7040513          	addi	a0,s0,-144
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	776080e7          	jalr	1910(ra) # 80004f8a <create>
     argint(2, &minor) < 0 ||
    8000581c:	c919                	beqz	a0,80005832 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	09c080e7          	jalr	156(ra) # 800038ba <iunlockput>
  end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	884080e7          	jalr	-1916(ra) # 800040aa <end_op>
  return 0;
    8000582e:	4501                	li	a0,0
    80005830:	a031                	j	8000583c <sys_mknod+0x80>
    end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	878080e7          	jalr	-1928(ra) # 800040aa <end_op>
    return -1;
    8000583a:	557d                	li	a0,-1
}
    8000583c:	60ea                	ld	ra,152(sp)
    8000583e:	644a                	ld	s0,144(sp)
    80005840:	610d                	addi	sp,sp,160
    80005842:	8082                	ret

0000000080005844 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005844:	7135                	addi	sp,sp,-160
    80005846:	ed06                	sd	ra,152(sp)
    80005848:	e922                	sd	s0,144(sp)
    8000584a:	e526                	sd	s1,136(sp)
    8000584c:	e14a                	sd	s2,128(sp)
    8000584e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005850:	ffffc097          	auipc	ra,0xffffc
    80005854:	144080e7          	jalr	324(ra) # 80001994 <myproc>
    80005858:	892a                	mv	s2,a0
  
  begin_op();
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	7d0080e7          	jalr	2000(ra) # 8000402a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005862:	08000613          	li	a2,128
    80005866:	f6040593          	addi	a1,s0,-160
    8000586a:	4501                	li	a0,0
    8000586c:	ffffd097          	auipc	ra,0xffffd
    80005870:	274080e7          	jalr	628(ra) # 80002ae0 <argstr>
    80005874:	04054b63          	bltz	a0,800058ca <sys_chdir+0x86>
    80005878:	f6040513          	addi	a0,s0,-160
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	592080e7          	jalr	1426(ra) # 80003e0e <namei>
    80005884:	84aa                	mv	s1,a0
    80005886:	c131                	beqz	a0,800058ca <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	dd0080e7          	jalr	-560(ra) # 80003658 <ilock>
  if(ip->type != T_DIR){
    80005890:	04449703          	lh	a4,68(s1)
    80005894:	4785                	li	a5,1
    80005896:	04f71063          	bne	a4,a5,800058d6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	e7e080e7          	jalr	-386(ra) # 8000371a <iunlock>
  iput(p->cwd);
    800058a4:	15093503          	ld	a0,336(s2)
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	f6a080e7          	jalr	-150(ra) # 80003812 <iput>
  end_op();
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	7fa080e7          	jalr	2042(ra) # 800040aa <end_op>
  p->cwd = ip;
    800058b8:	14993823          	sd	s1,336(s2)
  return 0;
    800058bc:	4501                	li	a0,0
}
    800058be:	60ea                	ld	ra,152(sp)
    800058c0:	644a                	ld	s0,144(sp)
    800058c2:	64aa                	ld	s1,136(sp)
    800058c4:	690a                	ld	s2,128(sp)
    800058c6:	610d                	addi	sp,sp,160
    800058c8:	8082                	ret
    end_op();
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	7e0080e7          	jalr	2016(ra) # 800040aa <end_op>
    return -1;
    800058d2:	557d                	li	a0,-1
    800058d4:	b7ed                	j	800058be <sys_chdir+0x7a>
    iunlockput(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	fe2080e7          	jalr	-30(ra) # 800038ba <iunlockput>
    end_op();
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	7ca080e7          	jalr	1994(ra) # 800040aa <end_op>
    return -1;
    800058e8:	557d                	li	a0,-1
    800058ea:	bfd1                	j	800058be <sys_chdir+0x7a>

00000000800058ec <sys_exec>:

uint64
sys_exec(void)
{
    800058ec:	7145                	addi	sp,sp,-464
    800058ee:	e786                	sd	ra,456(sp)
    800058f0:	e3a2                	sd	s0,448(sp)
    800058f2:	ff26                	sd	s1,440(sp)
    800058f4:	fb4a                	sd	s2,432(sp)
    800058f6:	f74e                	sd	s3,424(sp)
    800058f8:	f352                	sd	s4,416(sp)
    800058fa:	ef56                	sd	s5,408(sp)
    800058fc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058fe:	08000613          	li	a2,128
    80005902:	f4040593          	addi	a1,s0,-192
    80005906:	4501                	li	a0,0
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	1d8080e7          	jalr	472(ra) # 80002ae0 <argstr>
    return -1;
    80005910:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005912:	0c054a63          	bltz	a0,800059e6 <sys_exec+0xfa>
    80005916:	e3840593          	addi	a1,s0,-456
    8000591a:	4505                	li	a0,1
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	1a2080e7          	jalr	418(ra) # 80002abe <argaddr>
    80005924:	0c054163          	bltz	a0,800059e6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005928:	10000613          	li	a2,256
    8000592c:	4581                	li	a1,0
    8000592e:	e4040513          	addi	a0,s0,-448
    80005932:	ffffb097          	auipc	ra,0xffffb
    80005936:	3a0080e7          	jalr	928(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000593a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000593e:	89a6                	mv	s3,s1
    80005940:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005942:	02000a13          	li	s4,32
    80005946:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000594a:	00391513          	slli	a0,s2,0x3
    8000594e:	e3040593          	addi	a1,s0,-464
    80005952:	e3843783          	ld	a5,-456(s0)
    80005956:	953e                	add	a0,a0,a5
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	0aa080e7          	jalr	170(ra) # 80002a02 <fetchaddr>
    80005960:	02054a63          	bltz	a0,80005994 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005964:	e3043783          	ld	a5,-464(s0)
    80005968:	c3b9                	beqz	a5,800059ae <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000596a:	ffffb097          	auipc	ra,0xffffb
    8000596e:	17c080e7          	jalr	380(ra) # 80000ae6 <kalloc>
    80005972:	85aa                	mv	a1,a0
    80005974:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005978:	cd11                	beqz	a0,80005994 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000597a:	6605                	lui	a2,0x1
    8000597c:	e3043503          	ld	a0,-464(s0)
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	0d4080e7          	jalr	212(ra) # 80002a54 <fetchstr>
    80005988:	00054663          	bltz	a0,80005994 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000598c:	0905                	addi	s2,s2,1
    8000598e:	09a1                	addi	s3,s3,8
    80005990:	fb491be3          	bne	s2,s4,80005946 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005994:	10048913          	addi	s2,s1,256
    80005998:	6088                	ld	a0,0(s1)
    8000599a:	c529                	beqz	a0,800059e4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	04e080e7          	jalr	78(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a4:	04a1                	addi	s1,s1,8
    800059a6:	ff2499e3          	bne	s1,s2,80005998 <sys_exec+0xac>
  return -1;
    800059aa:	597d                	li	s2,-1
    800059ac:	a82d                	j	800059e6 <sys_exec+0xfa>
      argv[i] = 0;
    800059ae:	0a8e                	slli	s5,s5,0x3
    800059b0:	fc040793          	addi	a5,s0,-64
    800059b4:	9abe                	add	s5,s5,a5
    800059b6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059ba:	e4040593          	addi	a1,s0,-448
    800059be:	f4040513          	addi	a0,s0,-192
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	194080e7          	jalr	404(ra) # 80004b56 <exec>
    800059ca:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059cc:	10048993          	addi	s3,s1,256
    800059d0:	6088                	ld	a0,0(s1)
    800059d2:	c911                	beqz	a0,800059e6 <sys_exec+0xfa>
    kfree(argv[i]);
    800059d4:	ffffb097          	auipc	ra,0xffffb
    800059d8:	016080e7          	jalr	22(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059dc:	04a1                	addi	s1,s1,8
    800059de:	ff3499e3          	bne	s1,s3,800059d0 <sys_exec+0xe4>
    800059e2:	a011                	j	800059e6 <sys_exec+0xfa>
  return -1;
    800059e4:	597d                	li	s2,-1
}
    800059e6:	854a                	mv	a0,s2
    800059e8:	60be                	ld	ra,456(sp)
    800059ea:	641e                	ld	s0,448(sp)
    800059ec:	74fa                	ld	s1,440(sp)
    800059ee:	795a                	ld	s2,432(sp)
    800059f0:	79ba                	ld	s3,424(sp)
    800059f2:	7a1a                	ld	s4,416(sp)
    800059f4:	6afa                	ld	s5,408(sp)
    800059f6:	6179                	addi	sp,sp,464
    800059f8:	8082                	ret

00000000800059fa <sys_pipe>:

uint64
sys_pipe(void)
{
    800059fa:	7139                	addi	sp,sp,-64
    800059fc:	fc06                	sd	ra,56(sp)
    800059fe:	f822                	sd	s0,48(sp)
    80005a00:	f426                	sd	s1,40(sp)
    80005a02:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a04:	ffffc097          	auipc	ra,0xffffc
    80005a08:	f90080e7          	jalr	-112(ra) # 80001994 <myproc>
    80005a0c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a0e:	fd840593          	addi	a1,s0,-40
    80005a12:	4501                	li	a0,0
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	0aa080e7          	jalr	170(ra) # 80002abe <argaddr>
    return -1;
    80005a1c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a1e:	0e054063          	bltz	a0,80005afe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a22:	fc840593          	addi	a1,s0,-56
    80005a26:	fd040513          	addi	a0,s0,-48
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	dfc080e7          	jalr	-516(ra) # 80004826 <pipealloc>
    return -1;
    80005a32:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a34:	0c054563          	bltz	a0,80005afe <sys_pipe+0x104>
  fd0 = -1;
    80005a38:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a3c:	fd043503          	ld	a0,-48(s0)
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	508080e7          	jalr	1288(ra) # 80004f48 <fdalloc>
    80005a48:	fca42223          	sw	a0,-60(s0)
    80005a4c:	08054c63          	bltz	a0,80005ae4 <sys_pipe+0xea>
    80005a50:	fc843503          	ld	a0,-56(s0)
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	4f4080e7          	jalr	1268(ra) # 80004f48 <fdalloc>
    80005a5c:	fca42023          	sw	a0,-64(s0)
    80005a60:	06054863          	bltz	a0,80005ad0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a64:	4691                	li	a3,4
    80005a66:	fc440613          	addi	a2,s0,-60
    80005a6a:	fd843583          	ld	a1,-40(s0)
    80005a6e:	68a8                	ld	a0,80(s1)
    80005a70:	ffffc097          	auipc	ra,0xffffc
    80005a74:	be6080e7          	jalr	-1050(ra) # 80001656 <copyout>
    80005a78:	02054063          	bltz	a0,80005a98 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a7c:	4691                	li	a3,4
    80005a7e:	fc040613          	addi	a2,s0,-64
    80005a82:	fd843583          	ld	a1,-40(s0)
    80005a86:	0591                	addi	a1,a1,4
    80005a88:	68a8                	ld	a0,80(s1)
    80005a8a:	ffffc097          	auipc	ra,0xffffc
    80005a8e:	bcc080e7          	jalr	-1076(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a92:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a94:	06055563          	bgez	a0,80005afe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a98:	fc442783          	lw	a5,-60(s0)
    80005a9c:	07e9                	addi	a5,a5,26
    80005a9e:	078e                	slli	a5,a5,0x3
    80005aa0:	97a6                	add	a5,a5,s1
    80005aa2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005aa6:	fc042503          	lw	a0,-64(s0)
    80005aaa:	0569                	addi	a0,a0,26
    80005aac:	050e                	slli	a0,a0,0x3
    80005aae:	9526                	add	a0,a0,s1
    80005ab0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ab4:	fd043503          	ld	a0,-48(s0)
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	a3e080e7          	jalr	-1474(ra) # 800044f6 <fileclose>
    fileclose(wf);
    80005ac0:	fc843503          	ld	a0,-56(s0)
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	a32080e7          	jalr	-1486(ra) # 800044f6 <fileclose>
    return -1;
    80005acc:	57fd                	li	a5,-1
    80005ace:	a805                	j	80005afe <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ad0:	fc442783          	lw	a5,-60(s0)
    80005ad4:	0007c863          	bltz	a5,80005ae4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ad8:	01a78513          	addi	a0,a5,26
    80005adc:	050e                	slli	a0,a0,0x3
    80005ade:	9526                	add	a0,a0,s1
    80005ae0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ae4:	fd043503          	ld	a0,-48(s0)
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	a0e080e7          	jalr	-1522(ra) # 800044f6 <fileclose>
    fileclose(wf);
    80005af0:	fc843503          	ld	a0,-56(s0)
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	a02080e7          	jalr	-1534(ra) # 800044f6 <fileclose>
    return -1;
    80005afc:	57fd                	li	a5,-1
}
    80005afe:	853e                	mv	a0,a5
    80005b00:	70e2                	ld	ra,56(sp)
    80005b02:	7442                	ld	s0,48(sp)
    80005b04:	74a2                	ld	s1,40(sp)
    80005b06:	6121                	addi	sp,sp,64
    80005b08:	8082                	ret
    80005b0a:	0000                	unimp
    80005b0c:	0000                	unimp
	...

0000000080005b10 <kernelvec>:
    80005b10:	7111                	addi	sp,sp,-256
    80005b12:	e006                	sd	ra,0(sp)
    80005b14:	e40a                	sd	sp,8(sp)
    80005b16:	e80e                	sd	gp,16(sp)
    80005b18:	ec12                	sd	tp,24(sp)
    80005b1a:	f016                	sd	t0,32(sp)
    80005b1c:	f41a                	sd	t1,40(sp)
    80005b1e:	f81e                	sd	t2,48(sp)
    80005b20:	fc22                	sd	s0,56(sp)
    80005b22:	e0a6                	sd	s1,64(sp)
    80005b24:	e4aa                	sd	a0,72(sp)
    80005b26:	e8ae                	sd	a1,80(sp)
    80005b28:	ecb2                	sd	a2,88(sp)
    80005b2a:	f0b6                	sd	a3,96(sp)
    80005b2c:	f4ba                	sd	a4,104(sp)
    80005b2e:	f8be                	sd	a5,112(sp)
    80005b30:	fcc2                	sd	a6,120(sp)
    80005b32:	e146                	sd	a7,128(sp)
    80005b34:	e54a                	sd	s2,136(sp)
    80005b36:	e94e                	sd	s3,144(sp)
    80005b38:	ed52                	sd	s4,152(sp)
    80005b3a:	f156                	sd	s5,160(sp)
    80005b3c:	f55a                	sd	s6,168(sp)
    80005b3e:	f95e                	sd	s7,176(sp)
    80005b40:	fd62                	sd	s8,184(sp)
    80005b42:	e1e6                	sd	s9,192(sp)
    80005b44:	e5ea                	sd	s10,200(sp)
    80005b46:	e9ee                	sd	s11,208(sp)
    80005b48:	edf2                	sd	t3,216(sp)
    80005b4a:	f1f6                	sd	t4,224(sp)
    80005b4c:	f5fa                	sd	t5,232(sp)
    80005b4e:	f9fe                	sd	t6,240(sp)
    80005b50:	d7ffc0ef          	jal	ra,800028ce <kerneltrap>
    80005b54:	6082                	ld	ra,0(sp)
    80005b56:	6122                	ld	sp,8(sp)
    80005b58:	61c2                	ld	gp,16(sp)
    80005b5a:	7282                	ld	t0,32(sp)
    80005b5c:	7322                	ld	t1,40(sp)
    80005b5e:	73c2                	ld	t2,48(sp)
    80005b60:	7462                	ld	s0,56(sp)
    80005b62:	6486                	ld	s1,64(sp)
    80005b64:	6526                	ld	a0,72(sp)
    80005b66:	65c6                	ld	a1,80(sp)
    80005b68:	6666                	ld	a2,88(sp)
    80005b6a:	7686                	ld	a3,96(sp)
    80005b6c:	7726                	ld	a4,104(sp)
    80005b6e:	77c6                	ld	a5,112(sp)
    80005b70:	7866                	ld	a6,120(sp)
    80005b72:	688a                	ld	a7,128(sp)
    80005b74:	692a                	ld	s2,136(sp)
    80005b76:	69ca                	ld	s3,144(sp)
    80005b78:	6a6a                	ld	s4,152(sp)
    80005b7a:	7a8a                	ld	s5,160(sp)
    80005b7c:	7b2a                	ld	s6,168(sp)
    80005b7e:	7bca                	ld	s7,176(sp)
    80005b80:	7c6a                	ld	s8,184(sp)
    80005b82:	6c8e                	ld	s9,192(sp)
    80005b84:	6d2e                	ld	s10,200(sp)
    80005b86:	6dce                	ld	s11,208(sp)
    80005b88:	6e6e                	ld	t3,216(sp)
    80005b8a:	7e8e                	ld	t4,224(sp)
    80005b8c:	7f2e                	ld	t5,232(sp)
    80005b8e:	7fce                	ld	t6,240(sp)
    80005b90:	6111                	addi	sp,sp,256
    80005b92:	10200073          	sret
    80005b96:	00000013          	nop
    80005b9a:	00000013          	nop
    80005b9e:	0001                	nop

0000000080005ba0 <timervec>:
    80005ba0:	34051573          	csrrw	a0,mscratch,a0
    80005ba4:	e10c                	sd	a1,0(a0)
    80005ba6:	e510                	sd	a2,8(a0)
    80005ba8:	e914                	sd	a3,16(a0)
    80005baa:	6d0c                	ld	a1,24(a0)
    80005bac:	7110                	ld	a2,32(a0)
    80005bae:	6194                	ld	a3,0(a1)
    80005bb0:	96b2                	add	a3,a3,a2
    80005bb2:	e194                	sd	a3,0(a1)
    80005bb4:	4589                	li	a1,2
    80005bb6:	14459073          	csrw	sip,a1
    80005bba:	6914                	ld	a3,16(a0)
    80005bbc:	6510                	ld	a2,8(a0)
    80005bbe:	610c                	ld	a1,0(a0)
    80005bc0:	34051573          	csrrw	a0,mscratch,a0
    80005bc4:	30200073          	mret
	...

0000000080005bca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bca:	1141                	addi	sp,sp,-16
    80005bcc:	e422                	sd	s0,8(sp)
    80005bce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bd0:	0c0007b7          	lui	a5,0xc000
    80005bd4:	4705                	li	a4,1
    80005bd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bd8:	c3d8                	sw	a4,4(a5)
}
    80005bda:	6422                	ld	s0,8(sp)
    80005bdc:	0141                	addi	sp,sp,16
    80005bde:	8082                	ret

0000000080005be0 <plicinithart>:

void
plicinithart(void)
{
    80005be0:	1141                	addi	sp,sp,-16
    80005be2:	e406                	sd	ra,8(sp)
    80005be4:	e022                	sd	s0,0(sp)
    80005be6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	d80080e7          	jalr	-640(ra) # 80001968 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bf0:	0085171b          	slliw	a4,a0,0x8
    80005bf4:	0c0027b7          	lui	a5,0xc002
    80005bf8:	97ba                	add	a5,a5,a4
    80005bfa:	40200713          	li	a4,1026
    80005bfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c02:	00d5151b          	slliw	a0,a0,0xd
    80005c06:	0c2017b7          	lui	a5,0xc201
    80005c0a:	953e                	add	a0,a0,a5
    80005c0c:	00052023          	sw	zero,0(a0)
}
    80005c10:	60a2                	ld	ra,8(sp)
    80005c12:	6402                	ld	s0,0(sp)
    80005c14:	0141                	addi	sp,sp,16
    80005c16:	8082                	ret

0000000080005c18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c18:	1141                	addi	sp,sp,-16
    80005c1a:	e406                	sd	ra,8(sp)
    80005c1c:	e022                	sd	s0,0(sp)
    80005c1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	d48080e7          	jalr	-696(ra) # 80001968 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c28:	00d5179b          	slliw	a5,a0,0xd
    80005c2c:	0c201537          	lui	a0,0xc201
    80005c30:	953e                	add	a0,a0,a5
  return irq;
}
    80005c32:	4148                	lw	a0,4(a0)
    80005c34:	60a2                	ld	ra,8(sp)
    80005c36:	6402                	ld	s0,0(sp)
    80005c38:	0141                	addi	sp,sp,16
    80005c3a:	8082                	ret

0000000080005c3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c3c:	1101                	addi	sp,sp,-32
    80005c3e:	ec06                	sd	ra,24(sp)
    80005c40:	e822                	sd	s0,16(sp)
    80005c42:	e426                	sd	s1,8(sp)
    80005c44:	1000                	addi	s0,sp,32
    80005c46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	d20080e7          	jalr	-736(ra) # 80001968 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c50:	00d5151b          	slliw	a0,a0,0xd
    80005c54:	0c2017b7          	lui	a5,0xc201
    80005c58:	97aa                	add	a5,a5,a0
    80005c5a:	c3c4                	sw	s1,4(a5)
}
    80005c5c:	60e2                	ld	ra,24(sp)
    80005c5e:	6442                	ld	s0,16(sp)
    80005c60:	64a2                	ld	s1,8(sp)
    80005c62:	6105                	addi	sp,sp,32
    80005c64:	8082                	ret

0000000080005c66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c66:	1141                	addi	sp,sp,-16
    80005c68:	e406                	sd	ra,8(sp)
    80005c6a:	e022                	sd	s0,0(sp)
    80005c6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c6e:	479d                	li	a5,7
    80005c70:	06a7c963          	blt	a5,a0,80005ce2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c74:	0001d797          	auipc	a5,0x1d
    80005c78:	38c78793          	addi	a5,a5,908 # 80023000 <disk>
    80005c7c:	00a78733          	add	a4,a5,a0
    80005c80:	6789                	lui	a5,0x2
    80005c82:	97ba                	add	a5,a5,a4
    80005c84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c88:	e7ad                	bnez	a5,80005cf2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c8a:	00451793          	slli	a5,a0,0x4
    80005c8e:	0001f717          	auipc	a4,0x1f
    80005c92:	37270713          	addi	a4,a4,882 # 80025000 <disk+0x2000>
    80005c96:	6314                	ld	a3,0(a4)
    80005c98:	96be                	add	a3,a3,a5
    80005c9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c9e:	6314                	ld	a3,0(a4)
    80005ca0:	96be                	add	a3,a3,a5
    80005ca2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ca6:	6314                	ld	a3,0(a4)
    80005ca8:	96be                	add	a3,a3,a5
    80005caa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cae:	6318                	ld	a4,0(a4)
    80005cb0:	97ba                	add	a5,a5,a4
    80005cb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cb6:	0001d797          	auipc	a5,0x1d
    80005cba:	34a78793          	addi	a5,a5,842 # 80023000 <disk>
    80005cbe:	97aa                	add	a5,a5,a0
    80005cc0:	6509                	lui	a0,0x2
    80005cc2:	953e                	add	a0,a0,a5
    80005cc4:	4785                	li	a5,1
    80005cc6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005cca:	0001f517          	auipc	a0,0x1f
    80005cce:	34e50513          	addi	a0,a0,846 # 80025018 <disk+0x2018>
    80005cd2:	ffffc097          	auipc	ra,0xffffc
    80005cd6:	512080e7          	jalr	1298(ra) # 800021e4 <wakeup>
}
    80005cda:	60a2                	ld	ra,8(sp)
    80005cdc:	6402                	ld	s0,0(sp)
    80005cde:	0141                	addi	sp,sp,16
    80005ce0:	8082                	ret
    panic("free_desc 1");
    80005ce2:	00003517          	auipc	a0,0x3
    80005ce6:	a7e50513          	addi	a0,a0,-1410 # 80008760 <syscalls+0x330>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	846080e7          	jalr	-1978(ra) # 80000530 <panic>
    panic("free_desc 2");
    80005cf2:	00003517          	auipc	a0,0x3
    80005cf6:	a7e50513          	addi	a0,a0,-1410 # 80008770 <syscalls+0x340>
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	836080e7          	jalr	-1994(ra) # 80000530 <panic>

0000000080005d02 <virtio_disk_init>:
{
    80005d02:	1101                	addi	sp,sp,-32
    80005d04:	ec06                	sd	ra,24(sp)
    80005d06:	e822                	sd	s0,16(sp)
    80005d08:	e426                	sd	s1,8(sp)
    80005d0a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d0c:	00003597          	auipc	a1,0x3
    80005d10:	a7458593          	addi	a1,a1,-1420 # 80008780 <syscalls+0x350>
    80005d14:	0001f517          	auipc	a0,0x1f
    80005d18:	41450513          	addi	a0,a0,1044 # 80025128 <disk+0x2128>
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	e2a080e7          	jalr	-470(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d24:	100017b7          	lui	a5,0x10001
    80005d28:	4398                	lw	a4,0(a5)
    80005d2a:	2701                	sext.w	a4,a4
    80005d2c:	747277b7          	lui	a5,0x74727
    80005d30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d34:	0ef71163          	bne	a4,a5,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d38:	100017b7          	lui	a5,0x10001
    80005d3c:	43dc                	lw	a5,4(a5)
    80005d3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d40:	4705                	li	a4,1
    80005d42:	0ce79a63          	bne	a5,a4,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d46:	100017b7          	lui	a5,0x10001
    80005d4a:	479c                	lw	a5,8(a5)
    80005d4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d4e:	4709                	li	a4,2
    80005d50:	0ce79363          	bne	a5,a4,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d54:	100017b7          	lui	a5,0x10001
    80005d58:	47d8                	lw	a4,12(a5)
    80005d5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d5c:	554d47b7          	lui	a5,0x554d4
    80005d60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d64:	0af71963          	bne	a4,a5,80005e16 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d68:	100017b7          	lui	a5,0x10001
    80005d6c:	4705                	li	a4,1
    80005d6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d70:	470d                	li	a4,3
    80005d72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d76:	c7ffe737          	lui	a4,0xc7ffe
    80005d7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d80:	2701                	sext.w	a4,a4
    80005d82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d84:	472d                	li	a4,11
    80005d86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d88:	473d                	li	a4,15
    80005d8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d8c:	6705                	lui	a4,0x1
    80005d8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d94:	5bdc                	lw	a5,52(a5)
    80005d96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d98:	c7d9                	beqz	a5,80005e26 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d9a:	471d                	li	a4,7
    80005d9c:	08f77d63          	bgeu	a4,a5,80005e36 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005da0:	100014b7          	lui	s1,0x10001
    80005da4:	47a1                	li	a5,8
    80005da6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005da8:	6609                	lui	a2,0x2
    80005daa:	4581                	li	a1,0
    80005dac:	0001d517          	auipc	a0,0x1d
    80005db0:	25450513          	addi	a0,a0,596 # 80023000 <disk>
    80005db4:	ffffb097          	auipc	ra,0xffffb
    80005db8:	f1e080e7          	jalr	-226(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dbc:	0001d717          	auipc	a4,0x1d
    80005dc0:	24470713          	addi	a4,a4,580 # 80023000 <disk>
    80005dc4:	00c75793          	srli	a5,a4,0xc
    80005dc8:	2781                	sext.w	a5,a5
    80005dca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dcc:	0001f797          	auipc	a5,0x1f
    80005dd0:	23478793          	addi	a5,a5,564 # 80025000 <disk+0x2000>
    80005dd4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005dd6:	0001d717          	auipc	a4,0x1d
    80005dda:	2aa70713          	addi	a4,a4,682 # 80023080 <disk+0x80>
    80005dde:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005de0:	0001e717          	auipc	a4,0x1e
    80005de4:	22070713          	addi	a4,a4,544 # 80024000 <disk+0x1000>
    80005de8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dea:	4705                	li	a4,1
    80005dec:	00e78c23          	sb	a4,24(a5)
    80005df0:	00e78ca3          	sb	a4,25(a5)
    80005df4:	00e78d23          	sb	a4,26(a5)
    80005df8:	00e78da3          	sb	a4,27(a5)
    80005dfc:	00e78e23          	sb	a4,28(a5)
    80005e00:	00e78ea3          	sb	a4,29(a5)
    80005e04:	00e78f23          	sb	a4,30(a5)
    80005e08:	00e78fa3          	sb	a4,31(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret
    panic("could not find virtio disk");
    80005e16:	00003517          	auipc	a0,0x3
    80005e1a:	97a50513          	addi	a0,a0,-1670 # 80008790 <syscalls+0x360>
    80005e1e:	ffffa097          	auipc	ra,0xffffa
    80005e22:	712080e7          	jalr	1810(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	98a50513          	addi	a0,a0,-1654 # 800087b0 <syscalls+0x380>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	702080e7          	jalr	1794(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	99a50513          	addi	a0,a0,-1638 # 800087d0 <syscalls+0x3a0>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	6f2080e7          	jalr	1778(ra) # 80000530 <panic>

0000000080005e46 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e46:	7159                	addi	sp,sp,-112
    80005e48:	f486                	sd	ra,104(sp)
    80005e4a:	f0a2                	sd	s0,96(sp)
    80005e4c:	eca6                	sd	s1,88(sp)
    80005e4e:	e8ca                	sd	s2,80(sp)
    80005e50:	e4ce                	sd	s3,72(sp)
    80005e52:	e0d2                	sd	s4,64(sp)
    80005e54:	fc56                	sd	s5,56(sp)
    80005e56:	f85a                	sd	s6,48(sp)
    80005e58:	f45e                	sd	s7,40(sp)
    80005e5a:	f062                	sd	s8,32(sp)
    80005e5c:	ec66                	sd	s9,24(sp)
    80005e5e:	e86a                	sd	s10,16(sp)
    80005e60:	1880                	addi	s0,sp,112
    80005e62:	892a                	mv	s2,a0
    80005e64:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e66:	00c52c83          	lw	s9,12(a0)
    80005e6a:	001c9c9b          	slliw	s9,s9,0x1
    80005e6e:	1c82                	slli	s9,s9,0x20
    80005e70:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e74:	0001f517          	auipc	a0,0x1f
    80005e78:	2b450513          	addi	a0,a0,692 # 80025128 <disk+0x2128>
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	d5a080e7          	jalr	-678(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005e84:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e86:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e88:	0001db97          	auipc	s7,0x1d
    80005e8c:	178b8b93          	addi	s7,s7,376 # 80023000 <disk>
    80005e90:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e94:	8a4e                	mv	s4,s3
    80005e96:	a051                	j	80005f1a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e98:	00fb86b3          	add	a3,s7,a5
    80005e9c:	96da                	add	a3,a3,s6
    80005e9e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ea2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ea4:	0207c563          	bltz	a5,80005ece <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ea8:	2485                	addiw	s1,s1,1
    80005eaa:	0711                	addi	a4,a4,4
    80005eac:	25548063          	beq	s1,s5,800060ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005eb0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005eb2:	0001f697          	auipc	a3,0x1f
    80005eb6:	16668693          	addi	a3,a3,358 # 80025018 <disk+0x2018>
    80005eba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005ebc:	0006c583          	lbu	a1,0(a3)
    80005ec0:	fde1                	bnez	a1,80005e98 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ec2:	2785                	addiw	a5,a5,1
    80005ec4:	0685                	addi	a3,a3,1
    80005ec6:	ff879be3          	bne	a5,s8,80005ebc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005eca:	57fd                	li	a5,-1
    80005ecc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ece:	02905a63          	blez	s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ed2:	f9042503          	lw	a0,-112(s0)
    80005ed6:	00000097          	auipc	ra,0x0
    80005eda:	d90080e7          	jalr	-624(ra) # 80005c66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ede:	4785                	li	a5,1
    80005ee0:	0297d163          	bge	a5,s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ee4:	f9442503          	lw	a0,-108(s0)
    80005ee8:	00000097          	auipc	ra,0x0
    80005eec:	d7e080e7          	jalr	-642(ra) # 80005c66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ef0:	4789                	li	a5,2
    80005ef2:	0097d863          	bge	a5,s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ef6:	f9842503          	lw	a0,-104(s0)
    80005efa:	00000097          	auipc	ra,0x0
    80005efe:	d6c080e7          	jalr	-660(ra) # 80005c66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f02:	0001f597          	auipc	a1,0x1f
    80005f06:	22658593          	addi	a1,a1,550 # 80025128 <disk+0x2128>
    80005f0a:	0001f517          	auipc	a0,0x1f
    80005f0e:	10e50513          	addi	a0,a0,270 # 80025018 <disk+0x2018>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	146080e7          	jalr	326(ra) # 80002058 <sleep>
  for(int i = 0; i < 3; i++){
    80005f1a:	f9040713          	addi	a4,s0,-112
    80005f1e:	84ce                	mv	s1,s3
    80005f20:	bf41                	j	80005eb0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f22:	20058713          	addi	a4,a1,512
    80005f26:	00471693          	slli	a3,a4,0x4
    80005f2a:	0001d717          	auipc	a4,0x1d
    80005f2e:	0d670713          	addi	a4,a4,214 # 80023000 <disk>
    80005f32:	9736                	add	a4,a4,a3
    80005f34:	4685                	li	a3,1
    80005f36:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f3a:	20058713          	addi	a4,a1,512
    80005f3e:	00471693          	slli	a3,a4,0x4
    80005f42:	0001d717          	auipc	a4,0x1d
    80005f46:	0be70713          	addi	a4,a4,190 # 80023000 <disk>
    80005f4a:	9736                	add	a4,a4,a3
    80005f4c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f50:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f54:	7679                	lui	a2,0xffffe
    80005f56:	963e                	add	a2,a2,a5
    80005f58:	0001f697          	auipc	a3,0x1f
    80005f5c:	0a868693          	addi	a3,a3,168 # 80025000 <disk+0x2000>
    80005f60:	6298                	ld	a4,0(a3)
    80005f62:	9732                	add	a4,a4,a2
    80005f64:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f66:	6298                	ld	a4,0(a3)
    80005f68:	9732                	add	a4,a4,a2
    80005f6a:	4541                	li	a0,16
    80005f6c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f6e:	6298                	ld	a4,0(a3)
    80005f70:	9732                	add	a4,a4,a2
    80005f72:	4505                	li	a0,1
    80005f74:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f78:	f9442703          	lw	a4,-108(s0)
    80005f7c:	6288                	ld	a0,0(a3)
    80005f7e:	962a                	add	a2,a2,a0
    80005f80:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f84:	0712                	slli	a4,a4,0x4
    80005f86:	6290                	ld	a2,0(a3)
    80005f88:	963a                	add	a2,a2,a4
    80005f8a:	05890513          	addi	a0,s2,88
    80005f8e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f90:	6294                	ld	a3,0(a3)
    80005f92:	96ba                	add	a3,a3,a4
    80005f94:	40000613          	li	a2,1024
    80005f98:	c690                	sw	a2,8(a3)
  if(write)
    80005f9a:	140d0063          	beqz	s10,800060da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f9e:	0001f697          	auipc	a3,0x1f
    80005fa2:	0626b683          	ld	a3,98(a3) # 80025000 <disk+0x2000>
    80005fa6:	96ba                	add	a3,a3,a4
    80005fa8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fac:	0001d817          	auipc	a6,0x1d
    80005fb0:	05480813          	addi	a6,a6,84 # 80023000 <disk>
    80005fb4:	0001f517          	auipc	a0,0x1f
    80005fb8:	04c50513          	addi	a0,a0,76 # 80025000 <disk+0x2000>
    80005fbc:	6114                	ld	a3,0(a0)
    80005fbe:	96ba                	add	a3,a3,a4
    80005fc0:	00c6d603          	lhu	a2,12(a3)
    80005fc4:	00166613          	ori	a2,a2,1
    80005fc8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fcc:	f9842683          	lw	a3,-104(s0)
    80005fd0:	6110                	ld	a2,0(a0)
    80005fd2:	9732                	add	a4,a4,a2
    80005fd4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fd8:	20058613          	addi	a2,a1,512
    80005fdc:	0612                	slli	a2,a2,0x4
    80005fde:	9642                	add	a2,a2,a6
    80005fe0:	577d                	li	a4,-1
    80005fe2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fe6:	00469713          	slli	a4,a3,0x4
    80005fea:	6114                	ld	a3,0(a0)
    80005fec:	96ba                	add	a3,a3,a4
    80005fee:	03078793          	addi	a5,a5,48
    80005ff2:	97c2                	add	a5,a5,a6
    80005ff4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005ff6:	611c                	ld	a5,0(a0)
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	4685                	li	a3,1
    80005ffc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005ffe:	611c                	ld	a5,0(a0)
    80006000:	97ba                	add	a5,a5,a4
    80006002:	4809                	li	a6,2
    80006004:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006008:	611c                	ld	a5,0(a0)
    8000600a:	973e                	add	a4,a4,a5
    8000600c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006010:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006014:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006018:	6518                	ld	a4,8(a0)
    8000601a:	00275783          	lhu	a5,2(a4)
    8000601e:	8b9d                	andi	a5,a5,7
    80006020:	0786                	slli	a5,a5,0x1
    80006022:	97ba                	add	a5,a5,a4
    80006024:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006028:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000602c:	6518                	ld	a4,8(a0)
    8000602e:	00275783          	lhu	a5,2(a4)
    80006032:	2785                	addiw	a5,a5,1
    80006034:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006038:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006044:	00492703          	lw	a4,4(s2)
    80006048:	4785                	li	a5,1
    8000604a:	02f71163          	bne	a4,a5,8000606c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000604e:	0001f997          	auipc	s3,0x1f
    80006052:	0da98993          	addi	s3,s3,218 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006056:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006058:	85ce                	mv	a1,s3
    8000605a:	854a                	mv	a0,s2
    8000605c:	ffffc097          	auipc	ra,0xffffc
    80006060:	ffc080e7          	jalr	-4(ra) # 80002058 <sleep>
  while(b->disk == 1) {
    80006064:	00492783          	lw	a5,4(s2)
    80006068:	fe9788e3          	beq	a5,s1,80006058 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000606c:	f9042903          	lw	s2,-112(s0)
    80006070:	20090793          	addi	a5,s2,512
    80006074:	00479713          	slli	a4,a5,0x4
    80006078:	0001d797          	auipc	a5,0x1d
    8000607c:	f8878793          	addi	a5,a5,-120 # 80023000 <disk>
    80006080:	97ba                	add	a5,a5,a4
    80006082:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006086:	0001f997          	auipc	s3,0x1f
    8000608a:	f7a98993          	addi	s3,s3,-134 # 80025000 <disk+0x2000>
    8000608e:	00491713          	slli	a4,s2,0x4
    80006092:	0009b783          	ld	a5,0(s3)
    80006096:	97ba                	add	a5,a5,a4
    80006098:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000609c:	854a                	mv	a0,s2
    8000609e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060a2:	00000097          	auipc	ra,0x0
    800060a6:	bc4080e7          	jalr	-1084(ra) # 80005c66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060aa:	8885                	andi	s1,s1,1
    800060ac:	f0ed                	bnez	s1,8000608e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060ae:	0001f517          	auipc	a0,0x1f
    800060b2:	07a50513          	addi	a0,a0,122 # 80025128 <disk+0x2128>
    800060b6:	ffffb097          	auipc	ra,0xffffb
    800060ba:	bd4080e7          	jalr	-1068(ra) # 80000c8a <release>
}
    800060be:	70a6                	ld	ra,104(sp)
    800060c0:	7406                	ld	s0,96(sp)
    800060c2:	64e6                	ld	s1,88(sp)
    800060c4:	6946                	ld	s2,80(sp)
    800060c6:	69a6                	ld	s3,72(sp)
    800060c8:	6a06                	ld	s4,64(sp)
    800060ca:	7ae2                	ld	s5,56(sp)
    800060cc:	7b42                	ld	s6,48(sp)
    800060ce:	7ba2                	ld	s7,40(sp)
    800060d0:	7c02                	ld	s8,32(sp)
    800060d2:	6ce2                	ld	s9,24(sp)
    800060d4:	6d42                	ld	s10,16(sp)
    800060d6:	6165                	addi	sp,sp,112
    800060d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060da:	0001f697          	auipc	a3,0x1f
    800060de:	f266b683          	ld	a3,-218(a3) # 80025000 <disk+0x2000>
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	4609                	li	a2,2
    800060e6:	00c69623          	sh	a2,12(a3)
    800060ea:	b5c9                	j	80005fac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060ec:	f9042583          	lw	a1,-112(s0)
    800060f0:	20058793          	addi	a5,a1,512
    800060f4:	0792                	slli	a5,a5,0x4
    800060f6:	0001d517          	auipc	a0,0x1d
    800060fa:	fb250513          	addi	a0,a0,-78 # 800230a8 <disk+0xa8>
    800060fe:	953e                	add	a0,a0,a5
  if(write)
    80006100:	e20d11e3          	bnez	s10,80005f22 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006104:	20058713          	addi	a4,a1,512
    80006108:	00471693          	slli	a3,a4,0x4
    8000610c:	0001d717          	auipc	a4,0x1d
    80006110:	ef470713          	addi	a4,a4,-268 # 80023000 <disk>
    80006114:	9736                	add	a4,a4,a3
    80006116:	0a072423          	sw	zero,168(a4)
    8000611a:	b505                	j	80005f3a <virtio_disk_rw+0xf4>

000000008000611c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000611c:	1101                	addi	sp,sp,-32
    8000611e:	ec06                	sd	ra,24(sp)
    80006120:	e822                	sd	s0,16(sp)
    80006122:	e426                	sd	s1,8(sp)
    80006124:	e04a                	sd	s2,0(sp)
    80006126:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006128:	0001f517          	auipc	a0,0x1f
    8000612c:	00050513          	mv	a0,a0
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	aa6080e7          	jalr	-1370(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006138:	10001737          	lui	a4,0x10001
    8000613c:	533c                	lw	a5,96(a4)
    8000613e:	8b8d                	andi	a5,a5,3
    80006140:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006142:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006146:	0001f797          	auipc	a5,0x1f
    8000614a:	eba78793          	addi	a5,a5,-326 # 80025000 <disk+0x2000>
    8000614e:	6b94                	ld	a3,16(a5)
    80006150:	0207d703          	lhu	a4,32(a5)
    80006154:	0026d783          	lhu	a5,2(a3)
    80006158:	06f70163          	beq	a4,a5,800061ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000615c:	0001d917          	auipc	s2,0x1d
    80006160:	ea490913          	addi	s2,s2,-348 # 80023000 <disk>
    80006164:	0001f497          	auipc	s1,0x1f
    80006168:	e9c48493          	addi	s1,s1,-356 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000616c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006170:	6898                	ld	a4,16(s1)
    80006172:	0204d783          	lhu	a5,32(s1)
    80006176:	8b9d                	andi	a5,a5,7
    80006178:	078e                	slli	a5,a5,0x3
    8000617a:	97ba                	add	a5,a5,a4
    8000617c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000617e:	20078713          	addi	a4,a5,512
    80006182:	0712                	slli	a4,a4,0x4
    80006184:	974a                	add	a4,a4,s2
    80006186:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000618a:	e731                	bnez	a4,800061d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000618c:	20078793          	addi	a5,a5,512
    80006190:	0792                	slli	a5,a5,0x4
    80006192:	97ca                	add	a5,a5,s2
    80006194:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006196:	00052223          	sw	zero,4(a0) # 8002512c <disk+0x212c>
    wakeup(b);
    8000619a:	ffffc097          	auipc	ra,0xffffc
    8000619e:	04a080e7          	jalr	74(ra) # 800021e4 <wakeup>

    disk.used_idx += 1;
    800061a2:	0204d783          	lhu	a5,32(s1)
    800061a6:	2785                	addiw	a5,a5,1
    800061a8:	17c2                	slli	a5,a5,0x30
    800061aa:	93c1                	srli	a5,a5,0x30
    800061ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061b0:	6898                	ld	a4,16(s1)
    800061b2:	00275703          	lhu	a4,2(a4)
    800061b6:	faf71be3          	bne	a4,a5,8000616c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061ba:	0001f517          	auipc	a0,0x1f
    800061be:	f6e50513          	addi	a0,a0,-146 # 80025128 <disk+0x2128>
    800061c2:	ffffb097          	auipc	ra,0xffffb
    800061c6:	ac8080e7          	jalr	-1336(ra) # 80000c8a <release>
}
    800061ca:	60e2                	ld	ra,24(sp)
    800061cc:	6442                	ld	s0,16(sp)
    800061ce:	64a2                	ld	s1,8(sp)
    800061d0:	6902                	ld	s2,0(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret
      panic("virtio_disk_intr status");
    800061d6:	00002517          	auipc	a0,0x2
    800061da:	61a50513          	addi	a0,a0,1562 # 800087f0 <syscalls+0x3c0>
    800061de:	ffffa097          	auipc	ra,0xffffa
    800061e2:	352080e7          	jalr	850(ra) # 80000530 <panic>
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
