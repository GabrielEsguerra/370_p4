
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	cac78793          	addi	a5,a5,-852 # 80005d10 <timervec>
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
    80000122:	398080e7          	jalr	920(ra) # 800024b6 <either_copyin>
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
    800001ca:	ef6080e7          	jalr	-266(ra) # 800020bc <sleep>
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
    80000206:	25e080e7          	jalr	606(ra) # 80002460 <either_copyout>
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
    800002e8:	228080e7          	jalr	552(ra) # 8000250c <procdump>
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
    8000043c:	e10080e7          	jalr	-496(ra) # 80002248 <wakeup>
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
    80000896:	9b6080e7          	jalr	-1610(ra) # 80002248 <wakeup>
    
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
    80000922:	79e080e7          	jalr	1950(ra) # 800020bc <sleep>
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
    80000ece:	8fa080e7          	jalr	-1798(ra) # 800027c4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	e7e080e7          	jalr	-386(ra) # 80005d50 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	fde080e7          	jalr	-34(ra) # 80001eb8 <scheduler>
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
    80000f46:	85a080e7          	jalr	-1958(ra) # 8000279c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	87a080e7          	jalr	-1926(ra) # 800027c4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	de8080e7          	jalr	-536(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	df6080e7          	jalr	-522(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	fd6080e7          	jalr	-42(ra) # 80002f38 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	666080e7          	jalr	1638(ra) # 800035d0 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	610080e7          	jalr	1552(ra) # 80004582 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	ef8080e7          	jalr	-264(ra) # 80005e72 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	cf8080e7          	jalr	-776(ra) # 80001c7a <userinit>
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
    800019e8:	e1c7a783          	lw	a5,-484(a5) # 80008800 <first.1685>
    800019ec:	eb89                	bnez	a5,800019fe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ee:	00001097          	auipc	ra,0x1
    800019f2:	dee080e7          	jalr	-530(ra) # 800027dc <usertrapret>
}
    800019f6:	60a2                	ld	ra,8(sp)
    800019f8:	6402                	ld	s0,0(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret
    first = 0;
    800019fe:	00007797          	auipc	a5,0x7
    80001a02:	e007a123          	sw	zero,-510(a5) # 80008800 <first.1685>
    fsinit(ROOTDEV);
    80001a06:	4505                	li	a0,1
    80001a08:	00002097          	auipc	ra,0x2
    80001a0c:	b48080e7          	jalr	-1208(ra) # 80003550 <fsinit>
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
    80001a34:	dd478793          	addi	a5,a5,-556 # 80008804 <nextpid>
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
    80001b80:	16048023          	sb	zero,352(s1)
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
  struct proc *p = myproc();
    80001baa:	00000097          	auipc	ra,0x0
    80001bae:	dea080e7          	jalr	-534(ra) # 80001994 <myproc>
  p->priority = 10;
    80001bb2:	47a9                	li	a5,10
    80001bb4:	14f53c23          	sd	a5,344(a0)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb8:	00010497          	auipc	s1,0x10
    80001bbc:	b1848493          	addi	s1,s1,-1256 # 800116d0 <proc>
    80001bc0:	00015917          	auipc	s2,0x15
    80001bc4:	71090913          	addi	s2,s2,1808 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	00c080e7          	jalr	12(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bd2:	4c9c                	lw	a5,24(s1)
    80001bd4:	cf81                	beqz	a5,80001bec <allocproc+0x4e>
      release(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	0b2080e7          	jalr	178(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be0:	17048493          	addi	s1,s1,368
    80001be4:	ff2492e3          	bne	s1,s2,80001bc8 <allocproc+0x2a>
  return 0;
    80001be8:	4481                	li	s1,0
    80001bea:	a889                	j	80001c3c <allocproc+0x9e>
  p->pid = allocpid();
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	e26080e7          	jalr	-474(ra) # 80001a12 <allocpid>
    80001bf4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bf6:	4785                	li	a5,1
    80001bf8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	eec080e7          	jalr	-276(ra) # 80000ae6 <kalloc>
    80001c02:	892a                	mv	s2,a0
    80001c04:	eca8                	sd	a0,88(s1)
    80001c06:	c131                	beqz	a0,80001c4a <allocproc+0xac>
  p->pagetable = proc_pagetable(p);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e4e080e7          	jalr	-434(ra) # 80001a58 <proc_pagetable>
    80001c12:	892a                	mv	s2,a0
    80001c14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c16:	c531                	beqz	a0,80001c62 <allocproc+0xc4>
  memset(&p->context, 0, sizeof(p->context));
    80001c18:	07000613          	li	a2,112
    80001c1c:	4581                	li	a1,0
    80001c1e:	06048513          	addi	a0,s1,96
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	0b0080e7          	jalr	176(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c2a:	00000797          	auipc	a5,0x0
    80001c2e:	da278793          	addi	a5,a5,-606 # 800019cc <forkret>
    80001c32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c34:	60bc                	ld	a5,64(s1)
    80001c36:	6705                	lui	a4,0x1
    80001c38:	97ba                	add	a5,a5,a4
    80001c3a:	f4bc                	sd	a5,104(s1)
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    freeproc(p);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	efa080e7          	jalr	-262(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	034080e7          	jalr	52(ra) # 80000c8a <release>
    return 0;
    80001c5e:	84ca                	mv	s1,s2
    80001c60:	bff1                	j	80001c3c <allocproc+0x9e>
    freeproc(p);
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	ee2080e7          	jalr	-286(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	01c080e7          	jalr	28(ra) # 80000c8a <release>
    return 0;
    80001c76:	84ca                	mv	s1,s2
    80001c78:	b7d1                	j	80001c3c <allocproc+0x9e>

0000000080001c7a <userinit>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	f1a080e7          	jalr	-230(ra) # 80001b9e <allocproc>
    80001c8c:	84aa                	mv	s1,a0
  initproc = p;
    80001c8e:	00007797          	auipc	a5,0x7
    80001c92:	38a7bd23          	sd	a0,922(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c96:	03400613          	li	a2,52
    80001c9a:	00007597          	auipc	a1,0x7
    80001c9e:	b7658593          	addi	a1,a1,-1162 # 80008810 <initcode>
    80001ca2:	6928                	ld	a0,80(a0)
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	6a8080e7          	jalr	1704(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cac:	6785                	lui	a5,0x1
    80001cae:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb0:	6cb8                	ld	a4,88(s1)
    80001cb2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb6:	6cb8                	ld	a4,88(s1)
    80001cb8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cba:	4641                	li	a2,16
    80001cbc:	00006597          	auipc	a1,0x6
    80001cc0:	52c58593          	addi	a1,a1,1324 # 800081e8 <digits+0x1a8>
    80001cc4:	16048513          	addi	a0,s1,352
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	160080e7          	jalr	352(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001cd0:	00006517          	auipc	a0,0x6
    80001cd4:	52850513          	addi	a0,a0,1320 # 800081f8 <digits+0x1b8>
    80001cd8:	00002097          	auipc	ra,0x2
    80001cdc:	2a6080e7          	jalr	678(ra) # 80003f7e <namei>
    80001ce0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce4:	478d                	li	a5,3
    80001ce6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	fa0080e7          	jalr	-96(ra) # 80000c8a <release>
}
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6105                	addi	sp,sp,32
    80001cfa:	8082                	ret

0000000080001cfc <growproc>:
{
    80001cfc:	1101                	addi	sp,sp,-32
    80001cfe:	ec06                	sd	ra,24(sp)
    80001d00:	e822                	sd	s0,16(sp)
    80001d02:	e426                	sd	s1,8(sp)
    80001d04:	e04a                	sd	s2,0(sp)
    80001d06:	1000                	addi	s0,sp,32
    80001d08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	c8a080e7          	jalr	-886(ra) # 80001994 <myproc>
    80001d12:	892a                	mv	s2,a0
  sz = p->sz;
    80001d14:	652c                	ld	a1,72(a0)
    80001d16:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d1a:	00904f63          	bgtz	s1,80001d38 <growproc+0x3c>
  } else if(n < 0){
    80001d1e:	0204cc63          	bltz	s1,80001d56 <growproc+0x5a>
  p->sz = sz;
    80001d22:	1602                	slli	a2,a2,0x20
    80001d24:	9201                	srli	a2,a2,0x20
    80001d26:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d38:	9e25                	addw	a2,a2,s1
    80001d3a:	1602                	slli	a2,a2,0x20
    80001d3c:	9201                	srli	a2,a2,0x20
    80001d3e:	1582                	slli	a1,a1,0x20
    80001d40:	9181                	srli	a1,a1,0x20
    80001d42:	6928                	ld	a0,80(a0)
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	6c2080e7          	jalr	1730(ra) # 80001406 <uvmalloc>
    80001d4c:	0005061b          	sext.w	a2,a0
    80001d50:	fa69                	bnez	a2,80001d22 <growproc+0x26>
      return -1;
    80001d52:	557d                	li	a0,-1
    80001d54:	bfe1                	j	80001d2c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d56:	9e25                	addw	a2,a2,s1
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	65c080e7          	jalr	1628(ra) # 800013be <uvmdealloc>
    80001d6a:	0005061b          	sext.w	a2,a0
    80001d6e:	bf55                	j	80001d22 <growproc+0x26>

0000000080001d70 <fork>:
{
    80001d70:	7179                	addi	sp,sp,-48
    80001d72:	f406                	sd	ra,40(sp)
    80001d74:	f022                	sd	s0,32(sp)
    80001d76:	ec26                	sd	s1,24(sp)
    80001d78:	e84a                	sd	s2,16(sp)
    80001d7a:	e44e                	sd	s3,8(sp)
    80001d7c:	e052                	sd	s4,0(sp)
    80001d7e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	c14080e7          	jalr	-1004(ra) # 80001994 <myproc>
    80001d88:	892a                	mv	s2,a0
  if(p->priority != 0) {
    80001d8a:	15853783          	ld	a5,344(a0)
    80001d8e:	c781                	beqz	a5,80001d96 <fork+0x26>
    np->priority = p->priority - 2;
    80001d90:	17f9                	addi	a5,a5,-2
    80001d92:	14f53c23          	sd	a5,344(a0)
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e08080e7          	jalr	-504(ra) # 80001b9e <allocproc>
    80001d9e:	89aa                	mv	s3,a0
    80001da0:	10050a63          	beqz	a0,80001eb4 <fork+0x144>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7a4080e7          	jalr	1956(ra) # 80001552 <uvmcopy>
    80001db6:	04054663          	bltz	a0,80001e02 <fork+0x92>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc2:	05893683          	ld	a3,88(s2)
    80001dc6:	87b6                	mv	a5,a3
    80001dc8:	0589b703          	ld	a4,88(s3)
    80001dcc:	12068693          	addi	a3,a3,288
    80001dd0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd4:	6788                	ld	a0,8(a5)
    80001dd6:	6b8c                	ld	a1,16(a5)
    80001dd8:	6f90                	ld	a2,24(a5)
    80001dda:	01073023          	sd	a6,0(a4)
    80001dde:	e708                	sd	a0,8(a4)
    80001de0:	eb0c                	sd	a1,16(a4)
    80001de2:	ef10                	sd	a2,24(a4)
    80001de4:	02078793          	addi	a5,a5,32
    80001de8:	02070713          	addi	a4,a4,32
    80001dec:	fed792e3          	bne	a5,a3,80001dd0 <fork+0x60>
  np->trapframe->a0 = 0;
    80001df0:	0589b783          	ld	a5,88(s3)
    80001df4:	0607b823          	sd	zero,112(a5)
    80001df8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfc:	15000a13          	li	s4,336
    80001e00:	a03d                	j	80001e2e <fork+0xbe>
    freeproc(np);
    80001e02:	854e                	mv	a0,s3
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d42080e7          	jalr	-702(ra) # 80001b46 <freeproc>
    release(&np->lock);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    return -1;
    80001e16:	5a7d                	li	s4,-1
    80001e18:	a069                	j	80001ea2 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	7fa080e7          	jalr	2042(ra) # 80004614 <filedup>
    80001e22:	009987b3          	add	a5,s3,s1
    80001e26:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	01448763          	beq	s1,s4,80001e38 <fork+0xc8>
    if(p->ofile[i])
    80001e2e:	009907b3          	add	a5,s2,s1
    80001e32:	6388                	ld	a0,0(a5)
    80001e34:	f17d                	bnez	a0,80001e1a <fork+0xaa>
    80001e36:	bfcd                	j	80001e28 <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e38:	15093503          	ld	a0,336(s2)
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	94e080e7          	jalr	-1714(ra) # 8000378a <idup>
    80001e44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e48:	4641                	li	a2,16
    80001e4a:	16090593          	addi	a1,s2,352
    80001e4e:	16098513          	addi	a0,s3,352
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fd6080e7          	jalr	-42(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e5a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e5e:	854e                	mv	a0,s3
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e2a080e7          	jalr	-470(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e68:	0000f497          	auipc	s1,0xf
    80001e6c:	45048493          	addi	s1,s1,1104 # 800112b8 <wait_lock>
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e7a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e0a080e7          	jalr	-502(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d4c080e7          	jalr	-692(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e92:	478d                	li	a5,3
    80001e94:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	df0080e7          	jalr	-528(ra) # 80000c8a <release>
}
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	70a2                	ld	ra,40(sp)
    80001ea6:	7402                	ld	s0,32(sp)
    80001ea8:	64e2                	ld	s1,24(sp)
    80001eaa:	6942                	ld	s2,16(sp)
    80001eac:	69a2                	ld	s3,8(sp)
    80001eae:	6a02                	ld	s4,0(sp)
    80001eb0:	6145                	addi	sp,sp,48
    80001eb2:	8082                	ret
    return -1;
    80001eb4:	5a7d                	li	s4,-1
    80001eb6:	b7f5                	j	80001ea2 <fork+0x132>

0000000080001eb8 <scheduler>:
{
    80001eb8:	715d                	addi	sp,sp,-80
    80001eba:	e486                	sd	ra,72(sp)
    80001ebc:	e0a2                	sd	s0,64(sp)
    80001ebe:	fc26                	sd	s1,56(sp)
    80001ec0:	f84a                	sd	s2,48(sp)
    80001ec2:	f44e                	sd	s3,40(sp)
    80001ec4:	f052                	sd	s4,32(sp)
    80001ec6:	ec56                	sd	s5,24(sp)
    80001ec8:	e85a                	sd	s6,16(sp)
    80001eca:	e45e                	sd	s7,8(sp)
    80001ecc:	e062                	sd	s8,0(sp)
    80001ece:	0880                	addi	s0,sp,80
    80001ed0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed4:	00779b93          	slli	s7,a5,0x7
    80001ed8:	0000f717          	auipc	a4,0xf
    80001edc:	3c870713          	addi	a4,a4,968 # 800112a0 <pid_lock>
    80001ee0:	975e                	add	a4,a4,s7
    80001ee2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee6:	0000f717          	auipc	a4,0xf
    80001eea:	3f270713          	addi	a4,a4,1010 # 800112d8 <cpus+0x8>
    80001eee:	9bba                	add	s7,s7,a4
          for(p = CURR_PRIORITY_PROC+1; p < &proc[NPROC]; p++) {
    80001ef0:	00015997          	auipc	s3,0x15
    80001ef4:	3e098993          	addi	s3,s3,992 # 800172d0 <tickslock>
        c->proc = p;
    80001ef8:	079e                	slli	a5,a5,0x7
    80001efa:	0000fa97          	auipc	s5,0xf
    80001efe:	3a6a8a93          	addi	s5,s5,934 # 800112a0 <pid_lock>
    80001f02:	9abe                	add	s5,s5,a5
                  checkPrev = 1;
    80001f04:	4b05                	li	s6,1
    80001f06:	a885                	j	80001f76 <scheduler+0xbe>
          for(p = CURR_PRIORITY_PROC+1; p < &proc[NPROC]; p++) {
    80001f08:	17048793          	addi	a5,s1,368
    80001f0c:	0537f063          	bgeu	a5,s3,80001f4c <scheduler+0x94>
    80001f10:	8a26                	mv	s4,s1
      int checkPrev = 0;
    80001f12:	4681                	li	a3,0
    80001f14:	a839                	j	80001f32 <scheduler+0x7a>
                if(p->priority < CURR_PRIORITY_PROC->priority && CURR_PRIORITY_PROC != temp) {
    80001f16:	1587b603          	ld	a2,344(a5)
    80001f1a:	158a3703          	ld	a4,344(s4)
    80001f1e:	00e67663          	bgeu	a2,a4,80001f2a <scheduler+0x72>
    80001f22:	01448463          	beq	s1,s4,80001f2a <scheduler+0x72>
    80001f26:	8a3e                	mv	s4,a5
    80001f28:	84be                	mv	s1,a5
          for(p = CURR_PRIORITY_PROC+1; p < &proc[NPROC]; p++) {
    80001f2a:	17078793          	addi	a5,a5,368
    80001f2e:	0337f063          	bgeu	a5,s3,80001f4e <scheduler+0x96>
            if(p->state != RUNNABLE) {
    80001f32:	4f98                	lw	a4,24(a5)
    80001f34:	ff271be3          	bne	a4,s2,80001f2a <scheduler+0x72>
              if(checkPrev == 0) {
    80001f38:	fef9                	bnez	a3,80001f16 <scheduler+0x5e>
                if(p->priority < CURR_PRIORITY_PROC->priority) {
    80001f3a:	1587b603          	ld	a2,344(a5)
    80001f3e:	158a3703          	ld	a4,344(s4)
    80001f42:	fee674e3          	bgeu	a2,a4,80001f2a <scheduler+0x72>
    80001f46:	8a3e                	mv	s4,a5
                  checkPrev = 1;
    80001f48:	86da                	mv	a3,s6
    80001f4a:	b7c5                	j	80001f2a <scheduler+0x72>
          for(p = CURR_PRIORITY_PROC+1; p < &proc[NPROC]; p++) {
    80001f4c:	8a26                	mv	s4,s1
        p->state = RUNNING;
    80001f4e:	018a2c23          	sw	s8,24(s4)
        c->proc = p;
    80001f52:	034ab823          	sd	s4,48(s5)
        swtch(&c->context, &p->context);
    80001f56:	060a0593          	addi	a1,s4,96
    80001f5a:	855e                	mv	a0,s7
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	7d6080e7          	jalr	2006(ra) # 80002732 <swtch>
        c->proc = 0;
    80001f64:	020ab823          	sd	zero,48(s5)
    80001f68:	84d2                	mv	s1,s4
    80001f6a:	a815                	j	80001f9e <scheduler+0xe6>
      release(&p->lock);
    80001f6c:	853e                	mv	a0,a5
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f7e:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f82:	0000f497          	auipc	s1,0xf
    80001f86:	74e48493          	addi	s1,s1,1870 # 800116d0 <proc>
      if (p->state != RUNNABLE) {
    80001f8a:	490d                	li	s2,3
        p->state = RUNNING;
    80001f8c:	4c11                	li	s8,4
      acquire(&p->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	c46080e7          	jalr	-954(ra) # 80000bd6 <acquire>
      if (p->state != RUNNABLE) {
    80001f98:	4c9c                	lw	a5,24(s1)
    80001f9a:	f72787e3          	beq	a5,s2,80001f08 <scheduler+0x50>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9e:	17048793          	addi	a5,s1,368
    80001fa2:	fd37f5e3          	bgeu	a5,s3,80001f6c <scheduler+0xb4>
    80001fa6:	84be                	mv	s1,a5
    80001fa8:	b7dd                	j	80001f8e <scheduler+0xd6>

0000000080001faa <sched>:
{
    80001faa:	7179                	addi	sp,sp,-48
    80001fac:	f406                	sd	ra,40(sp)
    80001fae:	f022                	sd	s0,32(sp)
    80001fb0:	ec26                	sd	s1,24(sp)
    80001fb2:	e84a                	sd	s2,16(sp)
    80001fb4:	e44e                	sd	s3,8(sp)
    80001fb6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	9dc080e7          	jalr	-1572(ra) # 80001994 <myproc>
    80001fc0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	b9a080e7          	jalr	-1126(ra) # 80000b5c <holding>
    80001fca:	c93d                	beqz	a0,80002040 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fcc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	0000f717          	auipc	a4,0xf
    80001fd6:	2ce70713          	addi	a4,a4,718 # 800112a0 <pid_lock>
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	0a87a703          	lw	a4,168(a5)
    80001fe0:	4785                	li	a5,1
    80001fe2:	06f71763          	bne	a4,a5,80002050 <sched+0xa6>
  if(p->state == RUNNING)
    80001fe6:	4c98                	lw	a4,24(s1)
    80001fe8:	4791                	li	a5,4
    80001fea:	06f70b63          	beq	a4,a5,80002060 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ff4:	efb5                	bnez	a5,80002070 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff8:	0000f917          	auipc	s2,0xf
    80001ffc:	2a890913          	addi	s2,s2,680 # 800112a0 <pid_lock>
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	97ca                	add	a5,a5,s2
    80002006:	0ac7a983          	lw	s3,172(a5)
    8000200a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f597          	auipc	a1,0xf
    80002014:	2c858593          	addi	a1,a1,712 # 800112d8 <cpus+0x8>
    80002018:	95be                	add	a1,a1,a5
    8000201a:	06048513          	addi	a0,s1,96
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	714080e7          	jalr	1812(ra) # 80002732 <swtch>
    80002026:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	97ca                	add	a5,a5,s2
    8000202e:	0b37a623          	sw	s3,172(a5)
}
    80002032:	70a2                	ld	ra,40(sp)
    80002034:	7402                	ld	s0,32(sp)
    80002036:	64e2                	ld	s1,24(sp)
    80002038:	6942                	ld	s2,16(sp)
    8000203a:	69a2                	ld	s3,8(sp)
    8000203c:	6145                	addi	sp,sp,48
    8000203e:	8082                	ret
    panic("sched p->lock");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1c050513          	addi	a0,a0,448 # 80008200 <digits+0x1c0>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4e8080e7          	jalr	1256(ra) # 80000530 <panic>
    panic("sched locks");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1c050513          	addi	a0,a0,448 # 80008210 <digits+0x1d0>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4d8080e7          	jalr	1240(ra) # 80000530 <panic>
    panic("sched running");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1c050513          	addi	a0,a0,448 # 80008220 <digits+0x1e0>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4c8080e7          	jalr	1224(ra) # 80000530 <panic>
    panic("sched interruptible");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1c050513          	addi	a0,a0,448 # 80008230 <digits+0x1f0>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4b8080e7          	jalr	1208(ra) # 80000530 <panic>

0000000080002080 <yield>:
{
    80002080:	1101                	addi	sp,sp,-32
    80002082:	ec06                	sd	ra,24(sp)
    80002084:	e822                	sd	s0,16(sp)
    80002086:	e426                	sd	s1,8(sp)
    80002088:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	90a080e7          	jalr	-1782(ra) # 80001994 <myproc>
    80002092:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b42080e7          	jalr	-1214(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000209c:	478d                	li	a5,3
    8000209e:	cc9c                	sw	a5,24(s1)
  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	f0a080e7          	jalr	-246(ra) # 80001faa <sched>
  release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	be0080e7          	jalr	-1056(ra) # 80000c8a <release>
}
    800020b2:	60e2                	ld	ra,24(sp)
    800020b4:	6442                	ld	s0,16(sp)
    800020b6:	64a2                	ld	s1,8(sp)
    800020b8:	6105                	addi	sp,sp,32
    800020ba:	8082                	ret

00000000800020bc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020bc:	7179                	addi	sp,sp,-48
    800020be:	f406                	sd	ra,40(sp)
    800020c0:	f022                	sd	s0,32(sp)
    800020c2:	ec26                	sd	s1,24(sp)
    800020c4:	e84a                	sd	s2,16(sp)
    800020c6:	e44e                	sd	s3,8(sp)
    800020c8:	1800                	addi	s0,sp,48
    800020ca:	89aa                	mv	s3,a0
    800020cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	8c6080e7          	jalr	-1850(ra) # 80001994 <myproc>
    800020d6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	afe080e7          	jalr	-1282(ra) # 80000bd6 <acquire>
  release(lk);
    800020e0:	854a                	mv	a0,s2
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	ba8080e7          	jalr	-1112(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020ea:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ee:	4789                	li	a5,2
    800020f0:	cc9c                	sw	a5,24(s1)

  sched();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	eb8080e7          	jalr	-328(ra) # 80001faa <sched>

  // Tidy up.
  p->chan = 0;
    800020fa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b8a080e7          	jalr	-1142(ra) # 80000c8a <release>
  acquire(lk);
    80002108:	854a                	mv	a0,s2
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	acc080e7          	jalr	-1332(ra) # 80000bd6 <acquire>
}
    80002112:	70a2                	ld	ra,40(sp)
    80002114:	7402                	ld	s0,32(sp)
    80002116:	64e2                	ld	s1,24(sp)
    80002118:	6942                	ld	s2,16(sp)
    8000211a:	69a2                	ld	s3,8(sp)
    8000211c:	6145                	addi	sp,sp,48
    8000211e:	8082                	ret

0000000080002120 <wait>:
{
    80002120:	715d                	addi	sp,sp,-80
    80002122:	e486                	sd	ra,72(sp)
    80002124:	e0a2                	sd	s0,64(sp)
    80002126:	fc26                	sd	s1,56(sp)
    80002128:	f84a                	sd	s2,48(sp)
    8000212a:	f44e                	sd	s3,40(sp)
    8000212c:	f052                	sd	s4,32(sp)
    8000212e:	ec56                	sd	s5,24(sp)
    80002130:	e85a                	sd	s6,16(sp)
    80002132:	e45e                	sd	s7,8(sp)
    80002134:	e062                	sd	s8,0(sp)
    80002136:	0880                	addi	s0,sp,80
    80002138:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	85a080e7          	jalr	-1958(ra) # 80001994 <myproc>
    80002142:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002144:	0000f517          	auipc	a0,0xf
    80002148:	17450513          	addi	a0,a0,372 # 800112b8 <wait_lock>
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a8a080e7          	jalr	-1398(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002154:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002156:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002158:	00015997          	auipc	s3,0x15
    8000215c:	17898993          	addi	s3,s3,376 # 800172d0 <tickslock>
        havekids = 1;
    80002160:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002162:	0000fc17          	auipc	s8,0xf
    80002166:	156c0c13          	addi	s8,s8,342 # 800112b8 <wait_lock>
    havekids = 0;
    8000216a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000216c:	0000f497          	auipc	s1,0xf
    80002170:	56448493          	addi	s1,s1,1380 # 800116d0 <proc>
    80002174:	a0bd                	j	800021e2 <wait+0xc2>
          pid = np->pid;
    80002176:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000217a:	000b0e63          	beqz	s6,80002196 <wait+0x76>
    8000217e:	4691                	li	a3,4
    80002180:	02c48613          	addi	a2,s1,44
    80002184:	85da                	mv	a1,s6
    80002186:	05093503          	ld	a0,80(s2)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	4cc080e7          	jalr	1228(ra) # 80001656 <copyout>
    80002192:	02054563          	bltz	a0,800021bc <wait+0x9c>
          freeproc(np);
    80002196:	8526                	mv	a0,s1
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	9ae080e7          	jalr	-1618(ra) # 80001b46 <freeproc>
          release(&np->lock);
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	ae8080e7          	jalr	-1304(ra) # 80000c8a <release>
          release(&wait_lock);
    800021aa:	0000f517          	auipc	a0,0xf
    800021ae:	10e50513          	addi	a0,a0,270 # 800112b8 <wait_lock>
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ad8080e7          	jalr	-1320(ra) # 80000c8a <release>
          return pid;
    800021ba:	a09d                	j	80002220 <wait+0x100>
            release(&np->lock);
    800021bc:	8526                	mv	a0,s1
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
            release(&wait_lock);
    800021c6:	0000f517          	auipc	a0,0xf
    800021ca:	0f250513          	addi	a0,a0,242 # 800112b8 <wait_lock>
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	abc080e7          	jalr	-1348(ra) # 80000c8a <release>
            return -1;
    800021d6:	59fd                	li	s3,-1
    800021d8:	a0a1                	j	80002220 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021da:	17048493          	addi	s1,s1,368
    800021de:	03348463          	beq	s1,s3,80002206 <wait+0xe6>
      if(np->parent == p){
    800021e2:	7c9c                	ld	a5,56(s1)
    800021e4:	ff279be3          	bne	a5,s2,800021da <wait+0xba>
        acquire(&np->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	9ec080e7          	jalr	-1556(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    800021f2:	4c9c                	lw	a5,24(s1)
    800021f4:	f94781e3          	beq	a5,s4,80002176 <wait+0x56>
        release(&np->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a90080e7          	jalr	-1392(ra) # 80000c8a <release>
        havekids = 1;
    80002202:	8756                	mv	a4,s5
    80002204:	bfd9                	j	800021da <wait+0xba>
    if(!havekids || p->killed){
    80002206:	c701                	beqz	a4,8000220e <wait+0xee>
    80002208:	02892783          	lw	a5,40(s2)
    8000220c:	c79d                	beqz	a5,8000223a <wait+0x11a>
      release(&wait_lock);
    8000220e:	0000f517          	auipc	a0,0xf
    80002212:	0aa50513          	addi	a0,a0,170 # 800112b8 <wait_lock>
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	a74080e7          	jalr	-1420(ra) # 80000c8a <release>
      return -1;
    8000221e:	59fd                	li	s3,-1
}
    80002220:	854e                	mv	a0,s3
    80002222:	60a6                	ld	ra,72(sp)
    80002224:	6406                	ld	s0,64(sp)
    80002226:	74e2                	ld	s1,56(sp)
    80002228:	7942                	ld	s2,48(sp)
    8000222a:	79a2                	ld	s3,40(sp)
    8000222c:	7a02                	ld	s4,32(sp)
    8000222e:	6ae2                	ld	s5,24(sp)
    80002230:	6b42                	ld	s6,16(sp)
    80002232:	6ba2                	ld	s7,8(sp)
    80002234:	6c02                	ld	s8,0(sp)
    80002236:	6161                	addi	sp,sp,80
    80002238:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000223a:	85e2                	mv	a1,s8
    8000223c:	854a                	mv	a0,s2
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	e7e080e7          	jalr	-386(ra) # 800020bc <sleep>
    havekids = 0;
    80002246:	b715                	j	8000216a <wait+0x4a>

0000000080002248 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002248:	7139                	addi	sp,sp,-64
    8000224a:	fc06                	sd	ra,56(sp)
    8000224c:	f822                	sd	s0,48(sp)
    8000224e:	f426                	sd	s1,40(sp)
    80002250:	f04a                	sd	s2,32(sp)
    80002252:	ec4e                	sd	s3,24(sp)
    80002254:	e852                	sd	s4,16(sp)
    80002256:	e456                	sd	s5,8(sp)
    80002258:	0080                	addi	s0,sp,64
    8000225a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000225c:	0000f497          	auipc	s1,0xf
    80002260:	47448493          	addi	s1,s1,1140 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002264:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002266:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002268:	00015917          	auipc	s2,0x15
    8000226c:	06890913          	addi	s2,s2,104 # 800172d0 <tickslock>
    80002270:	a821                	j	80002288 <wakeup+0x40>
        p->state = RUNNABLE;
    80002272:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a12080e7          	jalr	-1518(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002280:	17048493          	addi	s1,s1,368
    80002284:	03248463          	beq	s1,s2,800022ac <wakeup+0x64>
    if(p != myproc()){
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	70c080e7          	jalr	1804(ra) # 80001994 <myproc>
    80002290:	fea488e3          	beq	s1,a0,80002280 <wakeup+0x38>
      acquire(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	940080e7          	jalr	-1728(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000229e:	4c9c                	lw	a5,24(s1)
    800022a0:	fd379be3          	bne	a5,s3,80002276 <wakeup+0x2e>
    800022a4:	709c                	ld	a5,32(s1)
    800022a6:	fd4798e3          	bne	a5,s4,80002276 <wakeup+0x2e>
    800022aa:	b7e1                	j	80002272 <wakeup+0x2a>
    }
  }
}
    800022ac:	70e2                	ld	ra,56(sp)
    800022ae:	7442                	ld	s0,48(sp)
    800022b0:	74a2                	ld	s1,40(sp)
    800022b2:	7902                	ld	s2,32(sp)
    800022b4:	69e2                	ld	s3,24(sp)
    800022b6:	6a42                	ld	s4,16(sp)
    800022b8:	6aa2                	ld	s5,8(sp)
    800022ba:	6121                	addi	sp,sp,64
    800022bc:	8082                	ret

00000000800022be <reparent>:
{
    800022be:	7179                	addi	sp,sp,-48
    800022c0:	f406                	sd	ra,40(sp)
    800022c2:	f022                	sd	s0,32(sp)
    800022c4:	ec26                	sd	s1,24(sp)
    800022c6:	e84a                	sd	s2,16(sp)
    800022c8:	e44e                	sd	s3,8(sp)
    800022ca:	e052                	sd	s4,0(sp)
    800022cc:	1800                	addi	s0,sp,48
    800022ce:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d0:	0000f497          	auipc	s1,0xf
    800022d4:	40048493          	addi	s1,s1,1024 # 800116d0 <proc>
      pp->parent = initproc;
    800022d8:	00007a17          	auipc	s4,0x7
    800022dc:	d50a0a13          	addi	s4,s4,-688 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022e0:	00015997          	auipc	s3,0x15
    800022e4:	ff098993          	addi	s3,s3,-16 # 800172d0 <tickslock>
    800022e8:	a029                	j	800022f2 <reparent+0x34>
    800022ea:	17048493          	addi	s1,s1,368
    800022ee:	01348d63          	beq	s1,s3,80002308 <reparent+0x4a>
    if(pp->parent == p){
    800022f2:	7c9c                	ld	a5,56(s1)
    800022f4:	ff279be3          	bne	a5,s2,800022ea <reparent+0x2c>
      pp->parent = initproc;
    800022f8:	000a3503          	ld	a0,0(s4)
    800022fc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	f4a080e7          	jalr	-182(ra) # 80002248 <wakeup>
    80002306:	b7d5                	j	800022ea <reparent+0x2c>
}
    80002308:	70a2                	ld	ra,40(sp)
    8000230a:	7402                	ld	s0,32(sp)
    8000230c:	64e2                	ld	s1,24(sp)
    8000230e:	6942                	ld	s2,16(sp)
    80002310:	69a2                	ld	s3,8(sp)
    80002312:	6a02                	ld	s4,0(sp)
    80002314:	6145                	addi	sp,sp,48
    80002316:	8082                	ret

0000000080002318 <exit>:
{
    80002318:	7179                	addi	sp,sp,-48
    8000231a:	f406                	sd	ra,40(sp)
    8000231c:	f022                	sd	s0,32(sp)
    8000231e:	ec26                	sd	s1,24(sp)
    80002320:	e84a                	sd	s2,16(sp)
    80002322:	e44e                	sd	s3,8(sp)
    80002324:	e052                	sd	s4,0(sp)
    80002326:	1800                	addi	s0,sp,48
    80002328:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	66a080e7          	jalr	1642(ra) # 80001994 <myproc>
    80002332:	89aa                	mv	s3,a0
  if(p == initproc)
    80002334:	00007797          	auipc	a5,0x7
    80002338:	cf47b783          	ld	a5,-780(a5) # 80009028 <initproc>
    8000233c:	0d050493          	addi	s1,a0,208
    80002340:	15050913          	addi	s2,a0,336
    80002344:	02a79363          	bne	a5,a0,8000236a <exit+0x52>
    panic("init exiting");
    80002348:	00006517          	auipc	a0,0x6
    8000234c:	f0050513          	addi	a0,a0,-256 # 80008248 <digits+0x208>
    80002350:	ffffe097          	auipc	ra,0xffffe
    80002354:	1e0080e7          	jalr	480(ra) # 80000530 <panic>
      fileclose(f);
    80002358:	00002097          	auipc	ra,0x2
    8000235c:	30e080e7          	jalr	782(ra) # 80004666 <fileclose>
      p->ofile[fd] = 0;
    80002360:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002364:	04a1                	addi	s1,s1,8
    80002366:	01248563          	beq	s1,s2,80002370 <exit+0x58>
    if(p->ofile[fd]){
    8000236a:	6088                	ld	a0,0(s1)
    8000236c:	f575                	bnez	a0,80002358 <exit+0x40>
    8000236e:	bfdd                	j	80002364 <exit+0x4c>
  begin_op();
    80002370:	00002097          	auipc	ra,0x2
    80002374:	e2a080e7          	jalr	-470(ra) # 8000419a <begin_op>
  iput(p->cwd);
    80002378:	1509b503          	ld	a0,336(s3)
    8000237c:	00001097          	auipc	ra,0x1
    80002380:	606080e7          	jalr	1542(ra) # 80003982 <iput>
  end_op();
    80002384:	00002097          	auipc	ra,0x2
    80002388:	e96080e7          	jalr	-362(ra) # 8000421a <end_op>
  p->cwd = 0;
    8000238c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002390:	0000f497          	auipc	s1,0xf
    80002394:	f2848493          	addi	s1,s1,-216 # 800112b8 <wait_lock>
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	83c080e7          	jalr	-1988(ra) # 80000bd6 <acquire>
  reparent(p);
    800023a2:	854e                	mv	a0,s3
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	f1a080e7          	jalr	-230(ra) # 800022be <reparent>
  wakeup(p->parent);
    800023ac:	0389b503          	ld	a0,56(s3)
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	e98080e7          	jalr	-360(ra) # 80002248 <wakeup>
  acquire(&p->lock);
    800023b8:	854e                	mv	a0,s3
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	81c080e7          	jalr	-2020(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800023c2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023c6:	4795                	li	a5,5
    800023c8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8bc080e7          	jalr	-1860(ra) # 80000c8a <release>
  sched();
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	bd4080e7          	jalr	-1068(ra) # 80001faa <sched>
  panic("zombie exit");
    800023de:	00006517          	auipc	a0,0x6
    800023e2:	e7a50513          	addi	a0,a0,-390 # 80008258 <digits+0x218>
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	14a080e7          	jalr	330(ra) # 80000530 <panic>

00000000800023ee <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023ee:	7179                	addi	sp,sp,-48
    800023f0:	f406                	sd	ra,40(sp)
    800023f2:	f022                	sd	s0,32(sp)
    800023f4:	ec26                	sd	s1,24(sp)
    800023f6:	e84a                	sd	s2,16(sp)
    800023f8:	e44e                	sd	s3,8(sp)
    800023fa:	1800                	addi	s0,sp,48
    800023fc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023fe:	0000f497          	auipc	s1,0xf
    80002402:	2d248493          	addi	s1,s1,722 # 800116d0 <proc>
    80002406:	00015997          	auipc	s3,0x15
    8000240a:	eca98993          	addi	s3,s3,-310 # 800172d0 <tickslock>
    acquire(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7c6080e7          	jalr	1990(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002418:	589c                	lw	a5,48(s1)
    8000241a:	01278d63          	beq	a5,s2,80002434 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	86a080e7          	jalr	-1942(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002428:	17048493          	addi	s1,s1,368
    8000242c:	ff3491e3          	bne	s1,s3,8000240e <kill+0x20>
  }
  return -1;
    80002430:	557d                	li	a0,-1
    80002432:	a829                	j	8000244c <kill+0x5e>
      p->killed = 1;
    80002434:	4785                	li	a5,1
    80002436:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002438:	4c98                	lw	a4,24(s1)
    8000243a:	4789                	li	a5,2
    8000243c:	00f70f63          	beq	a4,a5,8000245a <kill+0x6c>
      release(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	848080e7          	jalr	-1976(ra) # 80000c8a <release>
      return 0;
    8000244a:	4501                	li	a0,0
}
    8000244c:	70a2                	ld	ra,40(sp)
    8000244e:	7402                	ld	s0,32(sp)
    80002450:	64e2                	ld	s1,24(sp)
    80002452:	6942                	ld	s2,16(sp)
    80002454:	69a2                	ld	s3,8(sp)
    80002456:	6145                	addi	sp,sp,48
    80002458:	8082                	ret
        p->state = RUNNABLE;
    8000245a:	478d                	li	a5,3
    8000245c:	cc9c                	sw	a5,24(s1)
    8000245e:	b7cd                	j	80002440 <kill+0x52>

0000000080002460 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	e052                	sd	s4,0(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	84aa                	mv	s1,a0
    80002472:	892e                	mv	s2,a1
    80002474:	89b2                	mv	s3,a2
    80002476:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	51c080e7          	jalr	1308(ra) # 80001994 <myproc>
  if(user_dst){
    80002480:	c08d                	beqz	s1,800024a2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002482:	86d2                	mv	a3,s4
    80002484:	864e                	mv	a2,s3
    80002486:	85ca                	mv	a1,s2
    80002488:	6928                	ld	a0,80(a0)
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	1cc080e7          	jalr	460(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
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
    memmove((char *)dst, src, len);
    800024a2:	000a061b          	sext.w	a2,s4
    800024a6:	85ce                	mv	a1,s3
    800024a8:	854a                	mv	a0,s2
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	888080e7          	jalr	-1912(ra) # 80000d32 <memmove>
    return 0;
    800024b2:	8526                	mv	a0,s1
    800024b4:	bff9                	j	80002492 <either_copyout+0x32>

00000000800024b6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b6:	7179                	addi	sp,sp,-48
    800024b8:	f406                	sd	ra,40(sp)
    800024ba:	f022                	sd	s0,32(sp)
    800024bc:	ec26                	sd	s1,24(sp)
    800024be:	e84a                	sd	s2,16(sp)
    800024c0:	e44e                	sd	s3,8(sp)
    800024c2:	e052                	sd	s4,0(sp)
    800024c4:	1800                	addi	s0,sp,48
    800024c6:	892a                	mv	s2,a0
    800024c8:	84ae                	mv	s1,a1
    800024ca:	89b2                	mv	s3,a2
    800024cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	4c6080e7          	jalr	1222(ra) # 80001994 <myproc>
  if(user_src){
    800024d6:	c08d                	beqz	s1,800024f8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d8:	86d2                	mv	a3,s4
    800024da:	864e                	mv	a2,s3
    800024dc:	85ca                	mv	a1,s2
    800024de:	6928                	ld	a0,80(a0)
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	202080e7          	jalr	514(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e8:	70a2                	ld	ra,40(sp)
    800024ea:	7402                	ld	s0,32(sp)
    800024ec:	64e2                	ld	s1,24(sp)
    800024ee:	6942                	ld	s2,16(sp)
    800024f0:	69a2                	ld	s3,8(sp)
    800024f2:	6a02                	ld	s4,0(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f8:	000a061b          	sext.w	a2,s4
    800024fc:	85ce                	mv	a1,s3
    800024fe:	854a                	mv	a0,s2
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	832080e7          	jalr	-1998(ra) # 80000d32 <memmove>
    return 0;
    80002508:	8526                	mv	a0,s1
    8000250a:	bff9                	j	800024e8 <either_copyin+0x32>

000000008000250c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000250c:	715d                	addi	sp,sp,-80
    8000250e:	e486                	sd	ra,72(sp)
    80002510:	e0a2                	sd	s0,64(sp)
    80002512:	fc26                	sd	s1,56(sp)
    80002514:	f84a                	sd	s2,48(sp)
    80002516:	f44e                	sd	s3,40(sp)
    80002518:	f052                	sd	s4,32(sp)
    8000251a:	ec56                	sd	s5,24(sp)
    8000251c:	e85a                	sd	s6,16(sp)
    8000251e:	e45e                	sd	s7,8(sp)
    80002520:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002522:	00006517          	auipc	a0,0x6
    80002526:	ba650513          	addi	a0,a0,-1114 # 800080c8 <digits+0x88>
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	050080e7          	jalr	80(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002532:	0000f497          	auipc	s1,0xf
    80002536:	2fe48493          	addi	s1,s1,766 # 80011830 <proc+0x160>
    8000253a:	00015917          	auipc	s2,0x15
    8000253e:	ef690913          	addi	s2,s2,-266 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002542:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002544:	00006997          	auipc	s3,0x6
    80002548:	d2498993          	addi	s3,s3,-732 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000254c:	00006a97          	auipc	s5,0x6
    80002550:	d24a8a93          	addi	s5,s5,-732 # 80008270 <digits+0x230>
    printf("\n");
    80002554:	00006a17          	auipc	s4,0x6
    80002558:	b74a0a13          	addi	s4,s4,-1164 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255c:	00006b97          	auipc	s7,0x6
    80002560:	d4cb8b93          	addi	s7,s7,-692 # 800082a8 <states.1722>
    80002564:	a00d                	j	80002586 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002566:	ed06a583          	lw	a1,-304(a3)
    8000256a:	8556                	mv	a0,s5
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	00e080e7          	jalr	14(ra) # 8000057a <printf>
    printf("\n");
    80002574:	8552                	mv	a0,s4
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	004080e7          	jalr	4(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257e:	17048493          	addi	s1,s1,368
    80002582:	03248163          	beq	s1,s2,800025a4 <procdump+0x98>
    if(p->state == UNUSED)
    80002586:	86a6                	mv	a3,s1
    80002588:	eb84a783          	lw	a5,-328(s1)
    8000258c:	dbed                	beqz	a5,8000257e <procdump+0x72>
      state = "???";
    8000258e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002590:	fcfb6be3          	bltu	s6,a5,80002566 <procdump+0x5a>
    80002594:	1782                	slli	a5,a5,0x20
    80002596:	9381                	srli	a5,a5,0x20
    80002598:	078e                	slli	a5,a5,0x3
    8000259a:	97de                	add	a5,a5,s7
    8000259c:	6390                	ld	a2,0(a5)
    8000259e:	f661                	bnez	a2,80002566 <procdump+0x5a>
      state = "???";
    800025a0:	864e                	mv	a2,s3
    800025a2:	b7d1                	j	80002566 <procdump+0x5a>
  }
}
    800025a4:	60a6                	ld	ra,72(sp)
    800025a6:	6406                	ld	s0,64(sp)
    800025a8:	74e2                	ld	s1,56(sp)
    800025aa:	7942                	ld	s2,48(sp)
    800025ac:	79a2                	ld	s3,40(sp)
    800025ae:	7a02                	ld	s4,32(sp)
    800025b0:	6ae2                	ld	s5,24(sp)
    800025b2:	6b42                	ld	s6,16(sp)
    800025b4:	6ba2                	ld	s7,8(sp)
    800025b6:	6161                	addi	sp,sp,80
    800025b8:	8082                	ret

00000000800025ba <ps>:


int ps(uint64 addr) {
    800025ba:	7125                	addi	sp,sp,-416
    800025bc:	ef06                	sd	ra,408(sp)
    800025be:	eb22                	sd	s0,400(sp)
    800025c0:	e726                	sd	s1,392(sp)
    800025c2:	e34a                	sd	s2,384(sp)
    800025c4:	fece                	sd	s3,376(sp)
    800025c6:	fad2                	sd	s4,368(sp)
    800025c8:	f6d6                	sd	s5,360(sp)
    800025ca:	f2da                	sd	s6,352(sp)
    800025cc:	eede                	sd	s7,344(sp)
    800025ce:	eae2                	sd	s8,336(sp)
    800025d0:	e6e6                	sd	s9,328(sp)
    800025d2:	e2ea                	sd	s10,320(sp)
    800025d4:	fe6e                	sd	s11,312(sp)
    800025d6:	1300                	addi	s0,sp,416
    800025d8:	e6a43423          	sd	a0,-408(s0)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025e4:	10079073          	csrw	sstatus,a5
  struct ps_proc data[MAX_PROC];
  struct proc *p;
  intr_on(); //allow interrupts
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++) {
    800025e8:	e7840913          	addi	s2,s0,-392
    800025ec:	04000993          	li	s3,64
    800025f0:	0000f497          	auipc	s1,0xf
    800025f4:	0e048493          	addi	s1,s1,224 # 800116d0 <proc>
    if(p->state == USED) {
    800025f8:	4a05                	li	s4,1
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == SLEEPING) {
    800025fa:	4a89                	li	s5,2
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == RUNNABLE) {
    800025fc:	4b0d                	li	s6,3
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == RUNNING) {
    800025fe:	4b91                	li	s7,4
      safestrcpy(data[i].name, p->name, sizeof(p->name));
      data[i].pid = p->pid;
      data[i].priority = p->priority;
      ++i;
    }
    else if (p->state == ZOMBIE) {
    80002600:	4c15                	li	s8,5
      data[i].state = 5;
    80002602:	4c95                	li	s9,5
      data[i].state = 4;
    80002604:	4d91                	li	s11,4
      data[i].state = 3;
    80002606:	4d0d                	li	s10,3
    80002608:	a815                	j	8000263c <ps+0x82>
      data[i].state = 1;
    8000260a:	4785                	li	a5,1
    8000260c:	00f92023          	sw	a5,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    80002610:	4641                	li	a2,16
    80002612:	16048593          	addi	a1,s1,352
    80002616:	00c90513          	addi	a0,s2,12
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	80e080e7          	jalr	-2034(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    80002622:	589c                	lw	a5,48(s1)
    80002624:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    80002628:	1584b783          	ld	a5,344(s1)
    8000262c:	00f92423          	sw	a5,8(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80002630:	17048493          	addi	s1,s1,368
    80002634:	19fd                	addi	s3,s3,-1
    80002636:	0971                	addi	s2,s2,28
    80002638:	0a098a63          	beqz	s3,800026ec <ps+0x132>
    if(p->state == USED) {
    8000263c:	4c9c                	lw	a5,24(s1)
    8000263e:	fd4786e3          	beq	a5,s4,8000260a <ps+0x50>
    else if (p->state == SLEEPING) {
    80002642:	03578b63          	beq	a5,s5,80002678 <ps+0xbe>
    else if (p->state == RUNNABLE) {
    80002646:	05678d63          	beq	a5,s6,800026a0 <ps+0xe6>
    else if (p->state == RUNNING) {
    8000264a:	07778e63          	beq	a5,s7,800026c6 <ps+0x10c>
    else if (p->state == ZOMBIE) {
    8000264e:	ff8791e3          	bne	a5,s8,80002630 <ps+0x76>
      data[i].state = 5;
    80002652:	01992023          	sw	s9,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    80002656:	4641                	li	a2,16
    80002658:	16048593          	addi	a1,s1,352
    8000265c:	00c90513          	addi	a0,s2,12
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	7c8080e7          	jalr	1992(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    80002668:	589c                	lw	a5,48(s1)
    8000266a:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    8000266e:	1584b783          	ld	a5,344(s1)
    80002672:	00f92423          	sw	a5,8(s2)
      ++i;
    80002676:	bf6d                	j	80002630 <ps+0x76>
      data[i].state = 2;
    80002678:	4789                	li	a5,2
    8000267a:	00f92023          	sw	a5,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    8000267e:	4641                	li	a2,16
    80002680:	16048593          	addi	a1,s1,352
    80002684:	00c90513          	addi	a0,s2,12
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	7a0080e7          	jalr	1952(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    80002690:	589c                	lw	a5,48(s1)
    80002692:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    80002696:	1584b783          	ld	a5,344(s1)
    8000269a:	00f92423          	sw	a5,8(s2)
      ++i;
    8000269e:	bf49                	j	80002630 <ps+0x76>
      data[i].state = 3;
    800026a0:	01a92023          	sw	s10,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    800026a4:	4641                	li	a2,16
    800026a6:	16048593          	addi	a1,s1,352
    800026aa:	00c90513          	addi	a0,s2,12
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	77a080e7          	jalr	1914(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    800026b6:	589c                	lw	a5,48(s1)
    800026b8:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    800026bc:	1584b783          	ld	a5,344(s1)
    800026c0:	00f92423          	sw	a5,8(s2)
      ++i;
    800026c4:	b7b5                	j	80002630 <ps+0x76>
      data[i].state = 4;
    800026c6:	01b92023          	sw	s11,0(s2)
      safestrcpy(data[i].name, p->name, sizeof(p->name));
    800026ca:	4641                	li	a2,16
    800026cc:	16048593          	addi	a1,s1,352
    800026d0:	00c90513          	addi	a0,s2,12
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	754080e7          	jalr	1876(ra) # 80000e28 <safestrcpy>
      data[i].pid = p->pid;
    800026dc:	589c                	lw	a5,48(s1)
    800026de:	00f92223          	sw	a5,4(s2)
      data[i].priority = p->priority;
    800026e2:	1584b783          	ld	a5,344(s1)
    800026e6:	00f92423          	sw	a5,8(s2)
      ++i;
    800026ea:	b799                	j	80002630 <ps+0x76>
      ++i;
      continue;
    }
  }
    
  if(copyout(p->pagetable, addr, (char *)data, sizeof(data)) < 0) {
    800026ec:	11800693          	li	a3,280
    800026f0:	e7840613          	addi	a2,s0,-392
    800026f4:	e6843583          	ld	a1,-408(s0)
    800026f8:	00015517          	auipc	a0,0x15
    800026fc:	c2853503          	ld	a0,-984(a0) # 80017320 <bcache+0x38>
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	f56080e7          	jalr	-170(ra) # 80001656 <copyout>
    return -1;
  }
  return 1;
    80002708:	4785                	li	a5,1
  if(copyout(p->pagetable, addr, (char *)data, sizeof(data)) < 0) {
    8000270a:	02054263          	bltz	a0,8000272e <ps+0x174>
}
    8000270e:	853e                	mv	a0,a5
    80002710:	60fa                	ld	ra,408(sp)
    80002712:	645a                	ld	s0,400(sp)
    80002714:	64ba                	ld	s1,392(sp)
    80002716:	691a                	ld	s2,384(sp)
    80002718:	79f6                	ld	s3,376(sp)
    8000271a:	7a56                	ld	s4,368(sp)
    8000271c:	7ab6                	ld	s5,360(sp)
    8000271e:	7b16                	ld	s6,352(sp)
    80002720:	6bf6                	ld	s7,344(sp)
    80002722:	6c56                	ld	s8,336(sp)
    80002724:	6cb6                	ld	s9,328(sp)
    80002726:	6d16                	ld	s10,320(sp)
    80002728:	7df2                	ld	s11,312(sp)
    8000272a:	611d                	addi	sp,sp,416
    8000272c:	8082                	ret
    return -1;
    8000272e:	57fd                	li	a5,-1
    80002730:	bff9                	j	8000270e <ps+0x154>

0000000080002732 <swtch>:
    80002732:	00153023          	sd	ra,0(a0)
    80002736:	00253423          	sd	sp,8(a0)
    8000273a:	e900                	sd	s0,16(a0)
    8000273c:	ed04                	sd	s1,24(a0)
    8000273e:	03253023          	sd	s2,32(a0)
    80002742:	03353423          	sd	s3,40(a0)
    80002746:	03453823          	sd	s4,48(a0)
    8000274a:	03553c23          	sd	s5,56(a0)
    8000274e:	05653023          	sd	s6,64(a0)
    80002752:	05753423          	sd	s7,72(a0)
    80002756:	05853823          	sd	s8,80(a0)
    8000275a:	05953c23          	sd	s9,88(a0)
    8000275e:	07a53023          	sd	s10,96(a0)
    80002762:	07b53423          	sd	s11,104(a0)
    80002766:	0005b083          	ld	ra,0(a1)
    8000276a:	0085b103          	ld	sp,8(a1)
    8000276e:	6980                	ld	s0,16(a1)
    80002770:	6d84                	ld	s1,24(a1)
    80002772:	0205b903          	ld	s2,32(a1)
    80002776:	0285b983          	ld	s3,40(a1)
    8000277a:	0305ba03          	ld	s4,48(a1)
    8000277e:	0385ba83          	ld	s5,56(a1)
    80002782:	0405bb03          	ld	s6,64(a1)
    80002786:	0485bb83          	ld	s7,72(a1)
    8000278a:	0505bc03          	ld	s8,80(a1)
    8000278e:	0585bc83          	ld	s9,88(a1)
    80002792:	0605bd03          	ld	s10,96(a1)
    80002796:	0685bd83          	ld	s11,104(a1)
    8000279a:	8082                	ret

000000008000279c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000279c:	1141                	addi	sp,sp,-16
    8000279e:	e406                	sd	ra,8(sp)
    800027a0:	e022                	sd	s0,0(sp)
    800027a2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027a4:	00006597          	auipc	a1,0x6
    800027a8:	b3458593          	addi	a1,a1,-1228 # 800082d8 <states.1722+0x30>
    800027ac:	00015517          	auipc	a0,0x15
    800027b0:	b2450513          	addi	a0,a0,-1244 # 800172d0 <tickslock>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	392080e7          	jalr	914(ra) # 80000b46 <initlock>
}
    800027bc:	60a2                	ld	ra,8(sp)
    800027be:	6402                	ld	s0,0(sp)
    800027c0:	0141                	addi	sp,sp,16
    800027c2:	8082                	ret

00000000800027c4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027c4:	1141                	addi	sp,sp,-16
    800027c6:	e422                	sd	s0,8(sp)
    800027c8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ca:	00003797          	auipc	a5,0x3
    800027ce:	4b678793          	addi	a5,a5,1206 # 80005c80 <kernelvec>
    800027d2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027d6:	6422                	ld	s0,8(sp)
    800027d8:	0141                	addi	sp,sp,16
    800027da:	8082                	ret

00000000800027dc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027dc:	1141                	addi	sp,sp,-16
    800027de:	e406                	sd	ra,8(sp)
    800027e0:	e022                	sd	s0,0(sp)
    800027e2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	1b0080e7          	jalr	432(ra) # 80001994 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027f0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027f6:	00005617          	auipc	a2,0x5
    800027fa:	80a60613          	addi	a2,a2,-2038 # 80007000 <_trampoline>
    800027fe:	00005697          	auipc	a3,0x5
    80002802:	80268693          	addi	a3,a3,-2046 # 80007000 <_trampoline>
    80002806:	8e91                	sub	a3,a3,a2
    80002808:	040007b7          	lui	a5,0x4000
    8000280c:	17fd                	addi	a5,a5,-1
    8000280e:	07b2                	slli	a5,a5,0xc
    80002810:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002812:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002816:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002818:	180026f3          	csrr	a3,satp
    8000281c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000281e:	6d38                	ld	a4,88(a0)
    80002820:	6134                	ld	a3,64(a0)
    80002822:	6585                	lui	a1,0x1
    80002824:	96ae                	add	a3,a3,a1
    80002826:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002828:	6d38                	ld	a4,88(a0)
    8000282a:	00000697          	auipc	a3,0x0
    8000282e:	13868693          	addi	a3,a3,312 # 80002962 <usertrap>
    80002832:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002834:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002836:	8692                	mv	a3,tp
    80002838:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000283e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002842:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002846:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000284a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000284c:	6f18                	ld	a4,24(a4)
    8000284e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002852:	692c                	ld	a1,80(a0)
    80002854:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002856:	00005717          	auipc	a4,0x5
    8000285a:	83a70713          	addi	a4,a4,-1990 # 80007090 <userret>
    8000285e:	8f11                	sub	a4,a4,a2
    80002860:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002862:	577d                	li	a4,-1
    80002864:	177e                	slli	a4,a4,0x3f
    80002866:	8dd9                	or	a1,a1,a4
    80002868:	02000537          	lui	a0,0x2000
    8000286c:	157d                	addi	a0,a0,-1
    8000286e:	0536                	slli	a0,a0,0xd
    80002870:	9782                	jalr	a5
}
    80002872:	60a2                	ld	ra,8(sp)
    80002874:	6402                	ld	s0,0(sp)
    80002876:	0141                	addi	sp,sp,16
    80002878:	8082                	ret

000000008000287a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000287a:	1101                	addi	sp,sp,-32
    8000287c:	ec06                	sd	ra,24(sp)
    8000287e:	e822                	sd	s0,16(sp)
    80002880:	e426                	sd	s1,8(sp)
    80002882:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002884:	00015497          	auipc	s1,0x15
    80002888:	a4c48493          	addi	s1,s1,-1460 # 800172d0 <tickslock>
    8000288c:	8526                	mv	a0,s1
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	348080e7          	jalr	840(ra) # 80000bd6 <acquire>
  ticks++;
    80002896:	00006517          	auipc	a0,0x6
    8000289a:	79a50513          	addi	a0,a0,1946 # 80009030 <ticks>
    8000289e:	411c                	lw	a5,0(a0)
    800028a0:	2785                	addiw	a5,a5,1
    800028a2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028a4:	00000097          	auipc	ra,0x0
    800028a8:	9a4080e7          	jalr	-1628(ra) # 80002248 <wakeup>
  release(&tickslock);
    800028ac:	8526                	mv	a0,s1
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	3dc080e7          	jalr	988(ra) # 80000c8a <release>
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret

00000000800028c0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028c0:	1101                	addi	sp,sp,-32
    800028c2:	ec06                	sd	ra,24(sp)
    800028c4:	e822                	sd	s0,16(sp)
    800028c6:	e426                	sd	s1,8(sp)
    800028c8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ca:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028ce:	00074d63          	bltz	a4,800028e8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028d2:	57fd                	li	a5,-1
    800028d4:	17fe                	slli	a5,a5,0x3f
    800028d6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028d8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028da:	06f70363          	beq	a4,a5,80002940 <devintr+0x80>
  }
}
    800028de:	60e2                	ld	ra,24(sp)
    800028e0:	6442                	ld	s0,16(sp)
    800028e2:	64a2                	ld	s1,8(sp)
    800028e4:	6105                	addi	sp,sp,32
    800028e6:	8082                	ret
     (scause & 0xff) == 9){
    800028e8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028ec:	46a5                	li	a3,9
    800028ee:	fed792e3          	bne	a5,a3,800028d2 <devintr+0x12>
    int irq = plic_claim();
    800028f2:	00003097          	auipc	ra,0x3
    800028f6:	496080e7          	jalr	1174(ra) # 80005d88 <plic_claim>
    800028fa:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028fc:	47a9                	li	a5,10
    800028fe:	02f50763          	beq	a0,a5,8000292c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002902:	4785                	li	a5,1
    80002904:	02f50963          	beq	a0,a5,80002936 <devintr+0x76>
    return 1;
    80002908:	4505                	li	a0,1
    } else if(irq){
    8000290a:	d8f1                	beqz	s1,800028de <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000290c:	85a6                	mv	a1,s1
    8000290e:	00006517          	auipc	a0,0x6
    80002912:	9d250513          	addi	a0,a0,-1582 # 800082e0 <states.1722+0x38>
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	c64080e7          	jalr	-924(ra) # 8000057a <printf>
      plic_complete(irq);
    8000291e:	8526                	mv	a0,s1
    80002920:	00003097          	auipc	ra,0x3
    80002924:	48c080e7          	jalr	1164(ra) # 80005dac <plic_complete>
    return 1;
    80002928:	4505                	li	a0,1
    8000292a:	bf55                	j	800028de <devintr+0x1e>
      uartintr();
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	06e080e7          	jalr	110(ra) # 8000099a <uartintr>
    80002934:	b7ed                	j	8000291e <devintr+0x5e>
      virtio_disk_intr();
    80002936:	00004097          	auipc	ra,0x4
    8000293a:	956080e7          	jalr	-1706(ra) # 8000628c <virtio_disk_intr>
    8000293e:	b7c5                	j	8000291e <devintr+0x5e>
    if(cpuid() == 0){
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	028080e7          	jalr	40(ra) # 80001968 <cpuid>
    80002948:	c901                	beqz	a0,80002958 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000294a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000294e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002950:	14479073          	csrw	sip,a5
    return 2;
    80002954:	4509                	li	a0,2
    80002956:	b761                	j	800028de <devintr+0x1e>
      clockintr();
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	f22080e7          	jalr	-222(ra) # 8000287a <clockintr>
    80002960:	b7ed                	j	8000294a <devintr+0x8a>

0000000080002962 <usertrap>:
{
    80002962:	1101                	addi	sp,sp,-32
    80002964:	ec06                	sd	ra,24(sp)
    80002966:	e822                	sd	s0,16(sp)
    80002968:	e426                	sd	s1,8(sp)
    8000296a:	e04a                	sd	s2,0(sp)
    8000296c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002972:	1007f793          	andi	a5,a5,256
    80002976:	e3ad                	bnez	a5,800029d8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002978:	00003797          	auipc	a5,0x3
    8000297c:	30878793          	addi	a5,a5,776 # 80005c80 <kernelvec>
    80002980:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	010080e7          	jalr	16(ra) # 80001994 <myproc>
    8000298c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000298e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	14102773          	csrr	a4,sepc
    80002994:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002996:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000299a:	47a1                	li	a5,8
    8000299c:	04f71c63          	bne	a4,a5,800029f4 <usertrap+0x92>
    if(p->killed)
    800029a0:	551c                	lw	a5,40(a0)
    800029a2:	e3b9                	bnez	a5,800029e8 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029a4:	6cb8                	ld	a4,88(s1)
    800029a6:	6f1c                	ld	a5,24(a4)
    800029a8:	0791                	addi	a5,a5,4
    800029aa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b4:	10079073          	csrw	sstatus,a5
    syscall();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	2e0080e7          	jalr	736(ra) # 80002c98 <syscall>
  if(p->killed)
    800029c0:	549c                	lw	a5,40(s1)
    800029c2:	ebc1                	bnez	a5,80002a52 <usertrap+0xf0>
  usertrapret();
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	e18080e7          	jalr	-488(ra) # 800027dc <usertrapret>
}
    800029cc:	60e2                	ld	ra,24(sp)
    800029ce:	6442                	ld	s0,16(sp)
    800029d0:	64a2                	ld	s1,8(sp)
    800029d2:	6902                	ld	s2,0(sp)
    800029d4:	6105                	addi	sp,sp,32
    800029d6:	8082                	ret
    panic("usertrap: not from user mode");
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	92850513          	addi	a0,a0,-1752 # 80008300 <states.1722+0x58>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	b50080e7          	jalr	-1200(ra) # 80000530 <panic>
      exit(-1);
    800029e8:	557d                	li	a0,-1
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	92e080e7          	jalr	-1746(ra) # 80002318 <exit>
    800029f2:	bf4d                	j	800029a4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	ecc080e7          	jalr	-308(ra) # 800028c0 <devintr>
    800029fc:	892a                	mv	s2,a0
    800029fe:	c501                	beqz	a0,80002a06 <usertrap+0xa4>
  if(p->killed)
    80002a00:	549c                	lw	a5,40(s1)
    80002a02:	c3a1                	beqz	a5,80002a42 <usertrap+0xe0>
    80002a04:	a815                	j	80002a38 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a06:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a0a:	5890                	lw	a2,48(s1)
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	91450513          	addi	a0,a0,-1772 # 80008320 <states.1722+0x78>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b66080e7          	jalr	-1178(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a20:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a24:	00006517          	auipc	a0,0x6
    80002a28:	92c50513          	addi	a0,a0,-1748 # 80008350 <states.1722+0xa8>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	b4e080e7          	jalr	-1202(ra) # 8000057a <printf>
    p->killed = 1;
    80002a34:	4785                	li	a5,1
    80002a36:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a38:	557d                	li	a0,-1
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	8de080e7          	jalr	-1826(ra) # 80002318 <exit>
  if(which_dev == 2)
    80002a42:	4789                	li	a5,2
    80002a44:	f8f910e3          	bne	s2,a5,800029c4 <usertrap+0x62>
    yield();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	638080e7          	jalr	1592(ra) # 80002080 <yield>
    80002a50:	bf95                	j	800029c4 <usertrap+0x62>
  int which_dev = 0;
    80002a52:	4901                	li	s2,0
    80002a54:	b7d5                	j	80002a38 <usertrap+0xd6>

0000000080002a56 <kerneltrap>:
{
    80002a56:	7179                	addi	sp,sp,-48
    80002a58:	f406                	sd	ra,40(sp)
    80002a5a:	f022                	sd	s0,32(sp)
    80002a5c:	ec26                	sd	s1,24(sp)
    80002a5e:	e84a                	sd	s2,16(sp)
    80002a60:	e44e                	sd	s3,8(sp)
    80002a62:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a64:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a68:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a6c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a70:	1004f793          	andi	a5,s1,256
    80002a74:	cb85                	beqz	a5,80002aa4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a76:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a7a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a7c:	ef85                	bnez	a5,80002ab4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	e42080e7          	jalr	-446(ra) # 800028c0 <devintr>
    80002a86:	cd1d                	beqz	a0,80002ac4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a88:	4789                	li	a5,2
    80002a8a:	06f50a63          	beq	a0,a5,80002afe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a8e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a92:	10049073          	csrw	sstatus,s1
}
    80002a96:	70a2                	ld	ra,40(sp)
    80002a98:	7402                	ld	s0,32(sp)
    80002a9a:	64e2                	ld	s1,24(sp)
    80002a9c:	6942                	ld	s2,16(sp)
    80002a9e:	69a2                	ld	s3,8(sp)
    80002aa0:	6145                	addi	sp,sp,48
    80002aa2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	8cc50513          	addi	a0,a0,-1844 # 80008370 <states.1722+0xc8>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	a84080e7          	jalr	-1404(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	8e450513          	addi	a0,a0,-1820 # 80008398 <states.1722+0xf0>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	a74080e7          	jalr	-1420(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002ac4:	85ce                	mv	a1,s3
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	8f250513          	addi	a0,a0,-1806 # 800083b8 <states.1722+0x110>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	aac080e7          	jalr	-1364(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ada:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	8ea50513          	addi	a0,a0,-1814 # 800083c8 <states.1722+0x120>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	a94080e7          	jalr	-1388(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	8f250513          	addi	a0,a0,-1806 # 800083e0 <states.1722+0x138>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a3a080e7          	jalr	-1478(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	e96080e7          	jalr	-362(ra) # 80001994 <myproc>
    80002b06:	d541                	beqz	a0,80002a8e <kerneltrap+0x38>
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	e8c080e7          	jalr	-372(ra) # 80001994 <myproc>
    80002b10:	4d18                	lw	a4,24(a0)
    80002b12:	4791                	li	a5,4
    80002b14:	f6f71de3          	bne	a4,a5,80002a8e <kerneltrap+0x38>
    yield();
    80002b18:	fffff097          	auipc	ra,0xfffff
    80002b1c:	568080e7          	jalr	1384(ra) # 80002080 <yield>
    80002b20:	b7bd                	j	80002a8e <kerneltrap+0x38>

0000000080002b22 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b22:	1101                	addi	sp,sp,-32
    80002b24:	ec06                	sd	ra,24(sp)
    80002b26:	e822                	sd	s0,16(sp)
    80002b28:	e426                	sd	s1,8(sp)
    80002b2a:	1000                	addi	s0,sp,32
    80002b2c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	e66080e7          	jalr	-410(ra) # 80001994 <myproc>
  switch (n) {
    80002b36:	4795                	li	a5,5
    80002b38:	0497e163          	bltu	a5,s1,80002b7a <argraw+0x58>
    80002b3c:	048a                	slli	s1,s1,0x2
    80002b3e:	00006717          	auipc	a4,0x6
    80002b42:	8da70713          	addi	a4,a4,-1830 # 80008418 <states.1722+0x170>
    80002b46:	94ba                	add	s1,s1,a4
    80002b48:	409c                	lw	a5,0(s1)
    80002b4a:	97ba                	add	a5,a5,a4
    80002b4c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b4e:	6d3c                	ld	a5,88(a0)
    80002b50:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b52:	60e2                	ld	ra,24(sp)
    80002b54:	6442                	ld	s0,16(sp)
    80002b56:	64a2                	ld	s1,8(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret
    return p->trapframe->a1;
    80002b5c:	6d3c                	ld	a5,88(a0)
    80002b5e:	7fa8                	ld	a0,120(a5)
    80002b60:	bfcd                	j	80002b52 <argraw+0x30>
    return p->trapframe->a2;
    80002b62:	6d3c                	ld	a5,88(a0)
    80002b64:	63c8                	ld	a0,128(a5)
    80002b66:	b7f5                	j	80002b52 <argraw+0x30>
    return p->trapframe->a3;
    80002b68:	6d3c                	ld	a5,88(a0)
    80002b6a:	67c8                	ld	a0,136(a5)
    80002b6c:	b7dd                	j	80002b52 <argraw+0x30>
    return p->trapframe->a4;
    80002b6e:	6d3c                	ld	a5,88(a0)
    80002b70:	6bc8                	ld	a0,144(a5)
    80002b72:	b7c5                	j	80002b52 <argraw+0x30>
    return p->trapframe->a5;
    80002b74:	6d3c                	ld	a5,88(a0)
    80002b76:	6fc8                	ld	a0,152(a5)
    80002b78:	bfe9                	j	80002b52 <argraw+0x30>
  panic("argraw");
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	87650513          	addi	a0,a0,-1930 # 800083f0 <states.1722+0x148>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	9ae080e7          	jalr	-1618(ra) # 80000530 <panic>

0000000080002b8a <fetchaddr>:
{
    80002b8a:	1101                	addi	sp,sp,-32
    80002b8c:	ec06                	sd	ra,24(sp)
    80002b8e:	e822                	sd	s0,16(sp)
    80002b90:	e426                	sd	s1,8(sp)
    80002b92:	e04a                	sd	s2,0(sp)
    80002b94:	1000                	addi	s0,sp,32
    80002b96:	84aa                	mv	s1,a0
    80002b98:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	dfa080e7          	jalr	-518(ra) # 80001994 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ba2:	653c                	ld	a5,72(a0)
    80002ba4:	02f4f863          	bgeu	s1,a5,80002bd4 <fetchaddr+0x4a>
    80002ba8:	00848713          	addi	a4,s1,8
    80002bac:	02e7e663          	bltu	a5,a4,80002bd8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bb0:	46a1                	li	a3,8
    80002bb2:	8626                	mv	a2,s1
    80002bb4:	85ca                	mv	a1,s2
    80002bb6:	6928                	ld	a0,80(a0)
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	b2a080e7          	jalr	-1238(ra) # 800016e2 <copyin>
    80002bc0:	00a03533          	snez	a0,a0
    80002bc4:	40a00533          	neg	a0,a0
}
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6902                	ld	s2,0(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret
    return -1;
    80002bd4:	557d                	li	a0,-1
    80002bd6:	bfcd                	j	80002bc8 <fetchaddr+0x3e>
    80002bd8:	557d                	li	a0,-1
    80002bda:	b7fd                	j	80002bc8 <fetchaddr+0x3e>

0000000080002bdc <fetchstr>:
{
    80002bdc:	7179                	addi	sp,sp,-48
    80002bde:	f406                	sd	ra,40(sp)
    80002be0:	f022                	sd	s0,32(sp)
    80002be2:	ec26                	sd	s1,24(sp)
    80002be4:	e84a                	sd	s2,16(sp)
    80002be6:	e44e                	sd	s3,8(sp)
    80002be8:	1800                	addi	s0,sp,48
    80002bea:	892a                	mv	s2,a0
    80002bec:	84ae                	mv	s1,a1
    80002bee:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	da4080e7          	jalr	-604(ra) # 80001994 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bf8:	86ce                	mv	a3,s3
    80002bfa:	864a                	mv	a2,s2
    80002bfc:	85a6                	mv	a1,s1
    80002bfe:	6928                	ld	a0,80(a0)
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	b6e080e7          	jalr	-1170(ra) # 8000176e <copyinstr>
  if(err < 0)
    80002c08:	00054763          	bltz	a0,80002c16 <fetchstr+0x3a>
  return strlen(buf);
    80002c0c:	8526                	mv	a0,s1
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	24c080e7          	jalr	588(ra) # 80000e5a <strlen>
}
    80002c16:	70a2                	ld	ra,40(sp)
    80002c18:	7402                	ld	s0,32(sp)
    80002c1a:	64e2                	ld	s1,24(sp)
    80002c1c:	6942                	ld	s2,16(sp)
    80002c1e:	69a2                	ld	s3,8(sp)
    80002c20:	6145                	addi	sp,sp,48
    80002c22:	8082                	ret

0000000080002c24 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	ef2080e7          	jalr	-270(ra) # 80002b22 <argraw>
    80002c38:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c3a:	4501                	li	a0,0
    80002c3c:	60e2                	ld	ra,24(sp)
    80002c3e:	6442                	ld	s0,16(sp)
    80002c40:	64a2                	ld	s1,8(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret

0000000080002c46 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	e426                	sd	s1,8(sp)
    80002c4e:	1000                	addi	s0,sp,32
    80002c50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	ed0080e7          	jalr	-304(ra) # 80002b22 <argraw>
    80002c5a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c5c:	4501                	li	a0,0
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	64a2                	ld	s1,8(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret

0000000080002c68 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c68:	1101                	addi	sp,sp,-32
    80002c6a:	ec06                	sd	ra,24(sp)
    80002c6c:	e822                	sd	s0,16(sp)
    80002c6e:	e426                	sd	s1,8(sp)
    80002c70:	e04a                	sd	s2,0(sp)
    80002c72:	1000                	addi	s0,sp,32
    80002c74:	84ae                	mv	s1,a1
    80002c76:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	eaa080e7          	jalr	-342(ra) # 80002b22 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c80:	864a                	mv	a2,s2
    80002c82:	85a6                	mv	a1,s1
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	f58080e7          	jalr	-168(ra) # 80002bdc <fetchstr>
}
    80002c8c:	60e2                	ld	ra,24(sp)
    80002c8e:	6442                	ld	s0,16(sp)
    80002c90:	64a2                	ld	s1,8(sp)
    80002c92:	6902                	ld	s2,0(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret

0000000080002c98 <syscall>:
//[SYS_fork2]   sys_fork2,
};

void
syscall(void)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	e04a                	sd	s2,0(sp)
    80002ca2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	cf0080e7          	jalr	-784(ra) # 80001994 <myproc>
    80002cac:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cae:	05853903          	ld	s2,88(a0)
    80002cb2:	0a893783          	ld	a5,168(s2)
    80002cb6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cba:	37fd                	addiw	a5,a5,-1
    80002cbc:	4755                	li	a4,21
    80002cbe:	00f76f63          	bltu	a4,a5,80002cdc <syscall+0x44>
    80002cc2:	00369713          	slli	a4,a3,0x3
    80002cc6:	00005797          	auipc	a5,0x5
    80002cca:	76a78793          	addi	a5,a5,1898 # 80008430 <syscalls>
    80002cce:	97ba                	add	a5,a5,a4
    80002cd0:	639c                	ld	a5,0(a5)
    80002cd2:	c789                	beqz	a5,80002cdc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cd4:	9782                	jalr	a5
    80002cd6:	06a93823          	sd	a0,112(s2)
    80002cda:	a839                	j	80002cf8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cdc:	16048613          	addi	a2,s1,352
    80002ce0:	588c                	lw	a1,48(s1)
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	71650513          	addi	a0,a0,1814 # 800083f8 <states.1722+0x150>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	890080e7          	jalr	-1904(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cf2:	6cbc                	ld	a5,88(s1)
    80002cf4:	577d                	li	a4,-1
    80002cf6:	fbb8                	sd	a4,112(a5)
  }
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6902                	ld	s2,0(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d0c:	fec40593          	addi	a1,s0,-20
    80002d10:	4501                	li	a0,0
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f12080e7          	jalr	-238(ra) # 80002c24 <argint>
    return -1;
    80002d1a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d1c:	00054963          	bltz	a0,80002d2e <sys_exit+0x2a>
  exit(n);
    80002d20:	fec42503          	lw	a0,-20(s0)
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	5f4080e7          	jalr	1524(ra) # 80002318 <exit>
  return 0;  // not reached
    80002d2c:	4781                	li	a5,0
}
    80002d2e:	853e                	mv	a0,a5
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret

0000000080002d38 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d38:	1141                	addi	sp,sp,-16
    80002d3a:	e406                	sd	ra,8(sp)
    80002d3c:	e022                	sd	s0,0(sp)
    80002d3e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	c54080e7          	jalr	-940(ra) # 80001994 <myproc>
}
    80002d48:	5908                	lw	a0,48(a0)
    80002d4a:	60a2                	ld	ra,8(sp)
    80002d4c:	6402                	ld	s0,0(sp)
    80002d4e:	0141                	addi	sp,sp,16
    80002d50:	8082                	ret

0000000080002d52 <sys_fork>:

uint64
sys_fork(void)
{
    80002d52:	1141                	addi	sp,sp,-16
    80002d54:	e406                	sd	ra,8(sp)
    80002d56:	e022                	sd	s0,0(sp)
    80002d58:	0800                	addi	s0,sp,16
  return fork();
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	016080e7          	jalr	22(ra) # 80001d70 <fork>
}
    80002d62:	60a2                	ld	ra,8(sp)
    80002d64:	6402                	ld	s0,0(sp)
    80002d66:	0141                	addi	sp,sp,16
    80002d68:	8082                	ret

0000000080002d6a <sys_wait>:

uint64
sys_wait(void)
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d72:	fe840593          	addi	a1,s0,-24
    80002d76:	4501                	li	a0,0
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	ece080e7          	jalr	-306(ra) # 80002c46 <argaddr>
    80002d80:	87aa                	mv	a5,a0
    return -1;
    80002d82:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d84:	0007c863          	bltz	a5,80002d94 <sys_wait+0x2a>
  return wait(p);
    80002d88:	fe843503          	ld	a0,-24(s0)
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	394080e7          	jalr	916(ra) # 80002120 <wait>
}
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	6105                	addi	sp,sp,32
    80002d9a:	8082                	ret

0000000080002d9c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d9c:	7179                	addi	sp,sp,-48
    80002d9e:	f406                	sd	ra,40(sp)
    80002da0:	f022                	sd	s0,32(sp)
    80002da2:	ec26                	sd	s1,24(sp)
    80002da4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002da6:	fdc40593          	addi	a1,s0,-36
    80002daa:	4501                	li	a0,0
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	e78080e7          	jalr	-392(ra) # 80002c24 <argint>
    80002db4:	87aa                	mv	a5,a0
    return -1;
    80002db6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002db8:	0207c063          	bltz	a5,80002dd8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	bd8080e7          	jalr	-1064(ra) # 80001994 <myproc>
    80002dc4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dc6:	fdc42503          	lw	a0,-36(s0)
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	f32080e7          	jalr	-206(ra) # 80001cfc <growproc>
    80002dd2:	00054863          	bltz	a0,80002de2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002dd6:	8526                	mv	a0,s1
}
    80002dd8:	70a2                	ld	ra,40(sp)
    80002dda:	7402                	ld	s0,32(sp)
    80002ddc:	64e2                	ld	s1,24(sp)
    80002dde:	6145                	addi	sp,sp,48
    80002de0:	8082                	ret
    return -1;
    80002de2:	557d                	li	a0,-1
    80002de4:	bfd5                	j	80002dd8 <sys_sbrk+0x3c>

0000000080002de6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002de6:	7139                	addi	sp,sp,-64
    80002de8:	fc06                	sd	ra,56(sp)
    80002dea:	f822                	sd	s0,48(sp)
    80002dec:	f426                	sd	s1,40(sp)
    80002dee:	f04a                	sd	s2,32(sp)
    80002df0:	ec4e                	sd	s3,24(sp)
    80002df2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002df4:	fcc40593          	addi	a1,s0,-52
    80002df8:	4501                	li	a0,0
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	e2a080e7          	jalr	-470(ra) # 80002c24 <argint>
    return -1;
    80002e02:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e04:	06054563          	bltz	a0,80002e6e <sys_sleep+0x88>
  acquire(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	4c850513          	addi	a0,a0,1224 # 800172d0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	dc6080e7          	jalr	-570(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e18:	00006917          	auipc	s2,0x6
    80002e1c:	21892903          	lw	s2,536(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e20:	fcc42783          	lw	a5,-52(s0)
    80002e24:	cf85                	beqz	a5,80002e5c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e26:	00014997          	auipc	s3,0x14
    80002e2a:	4aa98993          	addi	s3,s3,1194 # 800172d0 <tickslock>
    80002e2e:	00006497          	auipc	s1,0x6
    80002e32:	20248493          	addi	s1,s1,514 # 80009030 <ticks>
    if(myproc()->killed){
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	b5e080e7          	jalr	-1186(ra) # 80001994 <myproc>
    80002e3e:	551c                	lw	a5,40(a0)
    80002e40:	ef9d                	bnez	a5,80002e7e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e42:	85ce                	mv	a1,s3
    80002e44:	8526                	mv	a0,s1
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	276080e7          	jalr	630(ra) # 800020bc <sleep>
  while(ticks - ticks0 < n){
    80002e4e:	409c                	lw	a5,0(s1)
    80002e50:	412787bb          	subw	a5,a5,s2
    80002e54:	fcc42703          	lw	a4,-52(s0)
    80002e58:	fce7efe3          	bltu	a5,a4,80002e36 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e5c:	00014517          	auipc	a0,0x14
    80002e60:	47450513          	addi	a0,a0,1140 # 800172d0 <tickslock>
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	e26080e7          	jalr	-474(ra) # 80000c8a <release>
  return 0;
    80002e6c:	4781                	li	a5,0
}
    80002e6e:	853e                	mv	a0,a5
    80002e70:	70e2                	ld	ra,56(sp)
    80002e72:	7442                	ld	s0,48(sp)
    80002e74:	74a2                	ld	s1,40(sp)
    80002e76:	7902                	ld	s2,32(sp)
    80002e78:	69e2                	ld	s3,24(sp)
    80002e7a:	6121                	addi	sp,sp,64
    80002e7c:	8082                	ret
      release(&tickslock);
    80002e7e:	00014517          	auipc	a0,0x14
    80002e82:	45250513          	addi	a0,a0,1106 # 800172d0 <tickslock>
    80002e86:	ffffe097          	auipc	ra,0xffffe
    80002e8a:	e04080e7          	jalr	-508(ra) # 80000c8a <release>
      return -1;
    80002e8e:	57fd                	li	a5,-1
    80002e90:	bff9                	j	80002e6e <sys_sleep+0x88>

0000000080002e92 <sys_kill>:

uint64
sys_kill(void)
{
    80002e92:	1101                	addi	sp,sp,-32
    80002e94:	ec06                	sd	ra,24(sp)
    80002e96:	e822                	sd	s0,16(sp)
    80002e98:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e9a:	fec40593          	addi	a1,s0,-20
    80002e9e:	4501                	li	a0,0
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	d84080e7          	jalr	-636(ra) # 80002c24 <argint>
    80002ea8:	87aa                	mv	a5,a0
    return -1;
    80002eaa:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002eac:	0007c863          	bltz	a5,80002ebc <sys_kill+0x2a>
  return kill(pid);
    80002eb0:	fec42503          	lw	a0,-20(s0)
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	53a080e7          	jalr	1338(ra) # 800023ee <kill>
}
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ec4:	1101                	addi	sp,sp,-32
    80002ec6:	ec06                	sd	ra,24(sp)
    80002ec8:	e822                	sd	s0,16(sp)
    80002eca:	e426                	sd	s1,8(sp)
    80002ecc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ece:	00014517          	auipc	a0,0x14
    80002ed2:	40250513          	addi	a0,a0,1026 # 800172d0 <tickslock>
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	d00080e7          	jalr	-768(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002ede:	00006497          	auipc	s1,0x6
    80002ee2:	1524a483          	lw	s1,338(s1) # 80009030 <ticks>
  release(&tickslock);
    80002ee6:	00014517          	auipc	a0,0x14
    80002eea:	3ea50513          	addi	a0,a0,1002 # 800172d0 <tickslock>
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	d9c080e7          	jalr	-612(ra) # 80000c8a <release>
  return xticks;
}
    80002ef6:	02049513          	slli	a0,s1,0x20
    80002efa:	9101                	srli	a0,a0,0x20
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	64a2                	ld	s1,8(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <sys_ps>:

uint64
sys_ps(void) {
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	1000                	addi	s0,sp,32
  uint64 addr;

  if(argaddr(0, &addr) < 0) {
    80002f0e:	fe840593          	addi	a1,s0,-24
    80002f12:	4501                	li	a0,0
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	d32080e7          	jalr	-718(ra) # 80002c46 <argaddr>
    80002f1c:	87aa                	mv	a5,a0
    return -1;
    80002f1e:	557d                	li	a0,-1
  if(argaddr(0, &addr) < 0) {
    80002f20:	0007c863          	bltz	a5,80002f30 <sys_ps+0x2a>
  }

  return ps(addr);
    80002f24:	fe843503          	ld	a0,-24(s0)
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	692080e7          	jalr	1682(ra) # 800025ba <ps>
}
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret

0000000080002f38 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	e84a                	sd	s2,16(sp)
    80002f42:	e44e                	sd	s3,8(sp)
    80002f44:	e052                	sd	s4,0(sp)
    80002f46:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f48:	00005597          	auipc	a1,0x5
    80002f4c:	5a058593          	addi	a1,a1,1440 # 800084e8 <syscalls+0xb8>
    80002f50:	00014517          	auipc	a0,0x14
    80002f54:	39850513          	addi	a0,a0,920 # 800172e8 <bcache>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	bee080e7          	jalr	-1042(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f60:	0001c797          	auipc	a5,0x1c
    80002f64:	38878793          	addi	a5,a5,904 # 8001f2e8 <bcache+0x8000>
    80002f68:	0001c717          	auipc	a4,0x1c
    80002f6c:	5e870713          	addi	a4,a4,1512 # 8001f550 <bcache+0x8268>
    80002f70:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f74:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f78:	00014497          	auipc	s1,0x14
    80002f7c:	38848493          	addi	s1,s1,904 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002f80:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f82:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f84:	00005a17          	auipc	s4,0x5
    80002f88:	56ca0a13          	addi	s4,s4,1388 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f8c:	2b893783          	ld	a5,696(s2)
    80002f90:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f92:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f96:	85d2                	mv	a1,s4
    80002f98:	01048513          	addi	a0,s1,16
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	4bc080e7          	jalr	1212(ra) # 80004458 <initsleeplock>
    bcache.head.next->prev = b;
    80002fa4:	2b893783          	ld	a5,696(s2)
    80002fa8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002faa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fae:	45848493          	addi	s1,s1,1112
    80002fb2:	fd349de3          	bne	s1,s3,80002f8c <binit+0x54>
  }
}
    80002fb6:	70a2                	ld	ra,40(sp)
    80002fb8:	7402                	ld	s0,32(sp)
    80002fba:	64e2                	ld	s1,24(sp)
    80002fbc:	6942                	ld	s2,16(sp)
    80002fbe:	69a2                	ld	s3,8(sp)
    80002fc0:	6a02                	ld	s4,0(sp)
    80002fc2:	6145                	addi	sp,sp,48
    80002fc4:	8082                	ret

0000000080002fc6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fc6:	7179                	addi	sp,sp,-48
    80002fc8:	f406                	sd	ra,40(sp)
    80002fca:	f022                	sd	s0,32(sp)
    80002fcc:	ec26                	sd	s1,24(sp)
    80002fce:	e84a                	sd	s2,16(sp)
    80002fd0:	e44e                	sd	s3,8(sp)
    80002fd2:	1800                	addi	s0,sp,48
    80002fd4:	89aa                	mv	s3,a0
    80002fd6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fd8:	00014517          	auipc	a0,0x14
    80002fdc:	31050513          	addi	a0,a0,784 # 800172e8 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	bf6080e7          	jalr	-1034(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fe8:	0001c497          	auipc	s1,0x1c
    80002fec:	5b84b483          	ld	s1,1464(s1) # 8001f5a0 <bcache+0x82b8>
    80002ff0:	0001c797          	auipc	a5,0x1c
    80002ff4:	56078793          	addi	a5,a5,1376 # 8001f550 <bcache+0x8268>
    80002ff8:	02f48f63          	beq	s1,a5,80003036 <bread+0x70>
    80002ffc:	873e                	mv	a4,a5
    80002ffe:	a021                	j	80003006 <bread+0x40>
    80003000:	68a4                	ld	s1,80(s1)
    80003002:	02e48a63          	beq	s1,a4,80003036 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003006:	449c                	lw	a5,8(s1)
    80003008:	ff379ce3          	bne	a5,s3,80003000 <bread+0x3a>
    8000300c:	44dc                	lw	a5,12(s1)
    8000300e:	ff2799e3          	bne	a5,s2,80003000 <bread+0x3a>
      b->refcnt++;
    80003012:	40bc                	lw	a5,64(s1)
    80003014:	2785                	addiw	a5,a5,1
    80003016:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003018:	00014517          	auipc	a0,0x14
    8000301c:	2d050513          	addi	a0,a0,720 # 800172e8 <bcache>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	c6a080e7          	jalr	-918(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003028:	01048513          	addi	a0,s1,16
    8000302c:	00001097          	auipc	ra,0x1
    80003030:	466080e7          	jalr	1126(ra) # 80004492 <acquiresleep>
      return b;
    80003034:	a8b9                	j	80003092 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003036:	0001c497          	auipc	s1,0x1c
    8000303a:	5624b483          	ld	s1,1378(s1) # 8001f598 <bcache+0x82b0>
    8000303e:	0001c797          	auipc	a5,0x1c
    80003042:	51278793          	addi	a5,a5,1298 # 8001f550 <bcache+0x8268>
    80003046:	00f48863          	beq	s1,a5,80003056 <bread+0x90>
    8000304a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000304c:	40bc                	lw	a5,64(s1)
    8000304e:	cf81                	beqz	a5,80003066 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003050:	64a4                	ld	s1,72(s1)
    80003052:	fee49de3          	bne	s1,a4,8000304c <bread+0x86>
  panic("bget: no buffers");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	4a250513          	addi	a0,a0,1186 # 800084f8 <syscalls+0xc8>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4d2080e7          	jalr	1234(ra) # 80000530 <panic>
      b->dev = dev;
    80003066:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000306a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000306e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003072:	4785                	li	a5,1
    80003074:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	27250513          	addi	a0,a0,626 # 800172e8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	c0c080e7          	jalr	-1012(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003086:	01048513          	addi	a0,s1,16
    8000308a:	00001097          	auipc	ra,0x1
    8000308e:	408080e7          	jalr	1032(ra) # 80004492 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003092:	409c                	lw	a5,0(s1)
    80003094:	cb89                	beqz	a5,800030a6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003096:	8526                	mv	a0,s1
    80003098:	70a2                	ld	ra,40(sp)
    8000309a:	7402                	ld	s0,32(sp)
    8000309c:	64e2                	ld	s1,24(sp)
    8000309e:	6942                	ld	s2,16(sp)
    800030a0:	69a2                	ld	s3,8(sp)
    800030a2:	6145                	addi	sp,sp,48
    800030a4:	8082                	ret
    virtio_disk_rw(b, 0);
    800030a6:	4581                	li	a1,0
    800030a8:	8526                	mv	a0,s1
    800030aa:	00003097          	auipc	ra,0x3
    800030ae:	f0c080e7          	jalr	-244(ra) # 80005fb6 <virtio_disk_rw>
    b->valid = 1;
    800030b2:	4785                	li	a5,1
    800030b4:	c09c                	sw	a5,0(s1)
  return b;
    800030b6:	b7c5                	j	80003096 <bread+0xd0>

00000000800030b8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030b8:	1101                	addi	sp,sp,-32
    800030ba:	ec06                	sd	ra,24(sp)
    800030bc:	e822                	sd	s0,16(sp)
    800030be:	e426                	sd	s1,8(sp)
    800030c0:	1000                	addi	s0,sp,32
    800030c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030c4:	0541                	addi	a0,a0,16
    800030c6:	00001097          	auipc	ra,0x1
    800030ca:	466080e7          	jalr	1126(ra) # 8000452c <holdingsleep>
    800030ce:	cd01                	beqz	a0,800030e6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030d0:	4585                	li	a1,1
    800030d2:	8526                	mv	a0,s1
    800030d4:	00003097          	auipc	ra,0x3
    800030d8:	ee2080e7          	jalr	-286(ra) # 80005fb6 <virtio_disk_rw>
}
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	64a2                	ld	s1,8(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret
    panic("bwrite");
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	42a50513          	addi	a0,a0,1066 # 80008510 <syscalls+0xe0>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	442080e7          	jalr	1090(ra) # 80000530 <panic>

00000000800030f6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	e04a                	sd	s2,0(sp)
    80003100:	1000                	addi	s0,sp,32
    80003102:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003104:	01050913          	addi	s2,a0,16
    80003108:	854a                	mv	a0,s2
    8000310a:	00001097          	auipc	ra,0x1
    8000310e:	422080e7          	jalr	1058(ra) # 8000452c <holdingsleep>
    80003112:	c92d                	beqz	a0,80003184 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003114:	854a                	mv	a0,s2
    80003116:	00001097          	auipc	ra,0x1
    8000311a:	3d2080e7          	jalr	978(ra) # 800044e8 <releasesleep>

  acquire(&bcache.lock);
    8000311e:	00014517          	auipc	a0,0x14
    80003122:	1ca50513          	addi	a0,a0,458 # 800172e8 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	ab0080e7          	jalr	-1360(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000312e:	40bc                	lw	a5,64(s1)
    80003130:	37fd                	addiw	a5,a5,-1
    80003132:	0007871b          	sext.w	a4,a5
    80003136:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003138:	eb05                	bnez	a4,80003168 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000313a:	68bc                	ld	a5,80(s1)
    8000313c:	64b8                	ld	a4,72(s1)
    8000313e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003140:	64bc                	ld	a5,72(s1)
    80003142:	68b8                	ld	a4,80(s1)
    80003144:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003146:	0001c797          	auipc	a5,0x1c
    8000314a:	1a278793          	addi	a5,a5,418 # 8001f2e8 <bcache+0x8000>
    8000314e:	2b87b703          	ld	a4,696(a5)
    80003152:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003154:	0001c717          	auipc	a4,0x1c
    80003158:	3fc70713          	addi	a4,a4,1020 # 8001f550 <bcache+0x8268>
    8000315c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000315e:	2b87b703          	ld	a4,696(a5)
    80003162:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003164:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003168:	00014517          	auipc	a0,0x14
    8000316c:	18050513          	addi	a0,a0,384 # 800172e8 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b1a080e7          	jalr	-1254(ra) # 80000c8a <release>
}
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	64a2                	ld	s1,8(sp)
    8000317e:	6902                	ld	s2,0(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret
    panic("brelse");
    80003184:	00005517          	auipc	a0,0x5
    80003188:	39450513          	addi	a0,a0,916 # 80008518 <syscalls+0xe8>
    8000318c:	ffffd097          	auipc	ra,0xffffd
    80003190:	3a4080e7          	jalr	932(ra) # 80000530 <panic>

0000000080003194 <bpin>:

void
bpin(struct buf *b) {
    80003194:	1101                	addi	sp,sp,-32
    80003196:	ec06                	sd	ra,24(sp)
    80003198:	e822                	sd	s0,16(sp)
    8000319a:	e426                	sd	s1,8(sp)
    8000319c:	1000                	addi	s0,sp,32
    8000319e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	14850513          	addi	a0,a0,328 # 800172e8 <bcache>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	a2e080e7          	jalr	-1490(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800031b0:	40bc                	lw	a5,64(s1)
    800031b2:	2785                	addiw	a5,a5,1
    800031b4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031b6:	00014517          	auipc	a0,0x14
    800031ba:	13250513          	addi	a0,a0,306 # 800172e8 <bcache>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
}
    800031c6:	60e2                	ld	ra,24(sp)
    800031c8:	6442                	ld	s0,16(sp)
    800031ca:	64a2                	ld	s1,8(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret

00000000800031d0 <bunpin>:

void
bunpin(struct buf *b) {
    800031d0:	1101                	addi	sp,sp,-32
    800031d2:	ec06                	sd	ra,24(sp)
    800031d4:	e822                	sd	s0,16(sp)
    800031d6:	e426                	sd	s1,8(sp)
    800031d8:	1000                	addi	s0,sp,32
    800031da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031dc:	00014517          	auipc	a0,0x14
    800031e0:	10c50513          	addi	a0,a0,268 # 800172e8 <bcache>
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	9f2080e7          	jalr	-1550(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031ec:	40bc                	lw	a5,64(s1)
    800031ee:	37fd                	addiw	a5,a5,-1
    800031f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f2:	00014517          	auipc	a0,0x14
    800031f6:	0f650513          	addi	a0,a0,246 # 800172e8 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	a90080e7          	jalr	-1392(ra) # 80000c8a <release>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6105                	addi	sp,sp,32
    8000320a:	8082                	ret

000000008000320c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	e426                	sd	s1,8(sp)
    80003214:	e04a                	sd	s2,0(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000321a:	00d5d59b          	srliw	a1,a1,0xd
    8000321e:	0001c797          	auipc	a5,0x1c
    80003222:	7a67a783          	lw	a5,1958(a5) # 8001f9c4 <sb+0x1c>
    80003226:	9dbd                	addw	a1,a1,a5
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	d9e080e7          	jalr	-610(ra) # 80002fc6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003230:	0074f713          	andi	a4,s1,7
    80003234:	4785                	li	a5,1
    80003236:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000323a:	14ce                	slli	s1,s1,0x33
    8000323c:	90d9                	srli	s1,s1,0x36
    8000323e:	00950733          	add	a4,a0,s1
    80003242:	05874703          	lbu	a4,88(a4)
    80003246:	00e7f6b3          	and	a3,a5,a4
    8000324a:	c69d                	beqz	a3,80003278 <bfree+0x6c>
    8000324c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000324e:	94aa                	add	s1,s1,a0
    80003250:	fff7c793          	not	a5,a5
    80003254:	8ff9                	and	a5,a5,a4
    80003256:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	118080e7          	jalr	280(ra) # 80004372 <log_write>
  brelse(bp);
    80003262:	854a                	mv	a0,s2
    80003264:	00000097          	auipc	ra,0x0
    80003268:	e92080e7          	jalr	-366(ra) # 800030f6 <brelse>
}
    8000326c:	60e2                	ld	ra,24(sp)
    8000326e:	6442                	ld	s0,16(sp)
    80003270:	64a2                	ld	s1,8(sp)
    80003272:	6902                	ld	s2,0(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret
    panic("freeing free block");
    80003278:	00005517          	auipc	a0,0x5
    8000327c:	2a850513          	addi	a0,a0,680 # 80008520 <syscalls+0xf0>
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	2b0080e7          	jalr	688(ra) # 80000530 <panic>

0000000080003288 <balloc>:
{
    80003288:	711d                	addi	sp,sp,-96
    8000328a:	ec86                	sd	ra,88(sp)
    8000328c:	e8a2                	sd	s0,80(sp)
    8000328e:	e4a6                	sd	s1,72(sp)
    80003290:	e0ca                	sd	s2,64(sp)
    80003292:	fc4e                	sd	s3,56(sp)
    80003294:	f852                	sd	s4,48(sp)
    80003296:	f456                	sd	s5,40(sp)
    80003298:	f05a                	sd	s6,32(sp)
    8000329a:	ec5e                	sd	s7,24(sp)
    8000329c:	e862                	sd	s8,16(sp)
    8000329e:	e466                	sd	s9,8(sp)
    800032a0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032a2:	0001c797          	auipc	a5,0x1c
    800032a6:	70a7a783          	lw	a5,1802(a5) # 8001f9ac <sb+0x4>
    800032aa:	cbd1                	beqz	a5,8000333e <balloc+0xb6>
    800032ac:	8baa                	mv	s7,a0
    800032ae:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032b0:	0001cb17          	auipc	s6,0x1c
    800032b4:	6f8b0b13          	addi	s6,s6,1784 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032ba:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032bc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032be:	6c89                	lui	s9,0x2
    800032c0:	a831                	j	800032dc <balloc+0x54>
    brelse(bp);
    800032c2:	854a                	mv	a0,s2
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	e32080e7          	jalr	-462(ra) # 800030f6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032cc:	015c87bb          	addw	a5,s9,s5
    800032d0:	00078a9b          	sext.w	s5,a5
    800032d4:	004b2703          	lw	a4,4(s6)
    800032d8:	06eaf363          	bgeu	s5,a4,8000333e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032dc:	41fad79b          	sraiw	a5,s5,0x1f
    800032e0:	0137d79b          	srliw	a5,a5,0x13
    800032e4:	015787bb          	addw	a5,a5,s5
    800032e8:	40d7d79b          	sraiw	a5,a5,0xd
    800032ec:	01cb2583          	lw	a1,28(s6)
    800032f0:	9dbd                	addw	a1,a1,a5
    800032f2:	855e                	mv	a0,s7
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	cd2080e7          	jalr	-814(ra) # 80002fc6 <bread>
    800032fc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fe:	004b2503          	lw	a0,4(s6)
    80003302:	000a849b          	sext.w	s1,s5
    80003306:	8662                	mv	a2,s8
    80003308:	faa4fde3          	bgeu	s1,a0,800032c2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000330c:	41f6579b          	sraiw	a5,a2,0x1f
    80003310:	01d7d69b          	srliw	a3,a5,0x1d
    80003314:	00c6873b          	addw	a4,a3,a2
    80003318:	00777793          	andi	a5,a4,7
    8000331c:	9f95                	subw	a5,a5,a3
    8000331e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003322:	4037571b          	sraiw	a4,a4,0x3
    80003326:	00e906b3          	add	a3,s2,a4
    8000332a:	0586c683          	lbu	a3,88(a3)
    8000332e:	00d7f5b3          	and	a1,a5,a3
    80003332:	cd91                	beqz	a1,8000334e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003334:	2605                	addiw	a2,a2,1
    80003336:	2485                	addiw	s1,s1,1
    80003338:	fd4618e3          	bne	a2,s4,80003308 <balloc+0x80>
    8000333c:	b759                	j	800032c2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000333e:	00005517          	auipc	a0,0x5
    80003342:	1fa50513          	addi	a0,a0,506 # 80008538 <syscalls+0x108>
    80003346:	ffffd097          	auipc	ra,0xffffd
    8000334a:	1ea080e7          	jalr	490(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000334e:	974a                	add	a4,a4,s2
    80003350:	8fd5                	or	a5,a5,a3
    80003352:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	01a080e7          	jalr	26(ra) # 80004372 <log_write>
        brelse(bp);
    80003360:	854a                	mv	a0,s2
    80003362:	00000097          	auipc	ra,0x0
    80003366:	d94080e7          	jalr	-620(ra) # 800030f6 <brelse>
  bp = bread(dev, bno);
    8000336a:	85a6                	mv	a1,s1
    8000336c:	855e                	mv	a0,s7
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	c58080e7          	jalr	-936(ra) # 80002fc6 <bread>
    80003376:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003378:	40000613          	li	a2,1024
    8000337c:	4581                	li	a1,0
    8000337e:	05850513          	addi	a0,a0,88
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	950080e7          	jalr	-1712(ra) # 80000cd2 <memset>
  log_write(bp);
    8000338a:	854a                	mv	a0,s2
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	fe6080e7          	jalr	-26(ra) # 80004372 <log_write>
  brelse(bp);
    80003394:	854a                	mv	a0,s2
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	d60080e7          	jalr	-672(ra) # 800030f6 <brelse>
}
    8000339e:	8526                	mv	a0,s1
    800033a0:	60e6                	ld	ra,88(sp)
    800033a2:	6446                	ld	s0,80(sp)
    800033a4:	64a6                	ld	s1,72(sp)
    800033a6:	6906                	ld	s2,64(sp)
    800033a8:	79e2                	ld	s3,56(sp)
    800033aa:	7a42                	ld	s4,48(sp)
    800033ac:	7aa2                	ld	s5,40(sp)
    800033ae:	7b02                	ld	s6,32(sp)
    800033b0:	6be2                	ld	s7,24(sp)
    800033b2:	6c42                	ld	s8,16(sp)
    800033b4:	6ca2                	ld	s9,8(sp)
    800033b6:	6125                	addi	sp,sp,96
    800033b8:	8082                	ret

00000000800033ba <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033ba:	7179                	addi	sp,sp,-48
    800033bc:	f406                	sd	ra,40(sp)
    800033be:	f022                	sd	s0,32(sp)
    800033c0:	ec26                	sd	s1,24(sp)
    800033c2:	e84a                	sd	s2,16(sp)
    800033c4:	e44e                	sd	s3,8(sp)
    800033c6:	e052                	sd	s4,0(sp)
    800033c8:	1800                	addi	s0,sp,48
    800033ca:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033cc:	47ad                	li	a5,11
    800033ce:	04b7fe63          	bgeu	a5,a1,8000342a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033d2:	ff45849b          	addiw	s1,a1,-12
    800033d6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033da:	0ff00793          	li	a5,255
    800033de:	0ae7e363          	bltu	a5,a4,80003484 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033e2:	08052583          	lw	a1,128(a0)
    800033e6:	c5ad                	beqz	a1,80003450 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033e8:	00092503          	lw	a0,0(s2)
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	bda080e7          	jalr	-1062(ra) # 80002fc6 <bread>
    800033f4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033f6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033fa:	02049593          	slli	a1,s1,0x20
    800033fe:	9181                	srli	a1,a1,0x20
    80003400:	058a                	slli	a1,a1,0x2
    80003402:	00b784b3          	add	s1,a5,a1
    80003406:	0004a983          	lw	s3,0(s1)
    8000340a:	04098d63          	beqz	s3,80003464 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000340e:	8552                	mv	a0,s4
    80003410:	00000097          	auipc	ra,0x0
    80003414:	ce6080e7          	jalr	-794(ra) # 800030f6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003418:	854e                	mv	a0,s3
    8000341a:	70a2                	ld	ra,40(sp)
    8000341c:	7402                	ld	s0,32(sp)
    8000341e:	64e2                	ld	s1,24(sp)
    80003420:	6942                	ld	s2,16(sp)
    80003422:	69a2                	ld	s3,8(sp)
    80003424:	6a02                	ld	s4,0(sp)
    80003426:	6145                	addi	sp,sp,48
    80003428:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000342a:	02059493          	slli	s1,a1,0x20
    8000342e:	9081                	srli	s1,s1,0x20
    80003430:	048a                	slli	s1,s1,0x2
    80003432:	94aa                	add	s1,s1,a0
    80003434:	0504a983          	lw	s3,80(s1)
    80003438:	fe0990e3          	bnez	s3,80003418 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000343c:	4108                	lw	a0,0(a0)
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	e4a080e7          	jalr	-438(ra) # 80003288 <balloc>
    80003446:	0005099b          	sext.w	s3,a0
    8000344a:	0534a823          	sw	s3,80(s1)
    8000344e:	b7e9                	j	80003418 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003450:	4108                	lw	a0,0(a0)
    80003452:	00000097          	auipc	ra,0x0
    80003456:	e36080e7          	jalr	-458(ra) # 80003288 <balloc>
    8000345a:	0005059b          	sext.w	a1,a0
    8000345e:	08b92023          	sw	a1,128(s2)
    80003462:	b759                	j	800033e8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003464:	00092503          	lw	a0,0(s2)
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	e20080e7          	jalr	-480(ra) # 80003288 <balloc>
    80003470:	0005099b          	sext.w	s3,a0
    80003474:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003478:	8552                	mv	a0,s4
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	ef8080e7          	jalr	-264(ra) # 80004372 <log_write>
    80003482:	b771                	j	8000340e <bmap+0x54>
  panic("bmap: out of range");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	0cc50513          	addi	a0,a0,204 # 80008550 <syscalls+0x120>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0a4080e7          	jalr	164(ra) # 80000530 <panic>

0000000080003494 <iget>:
{
    80003494:	7179                	addi	sp,sp,-48
    80003496:	f406                	sd	ra,40(sp)
    80003498:	f022                	sd	s0,32(sp)
    8000349a:	ec26                	sd	s1,24(sp)
    8000349c:	e84a                	sd	s2,16(sp)
    8000349e:	e44e                	sd	s3,8(sp)
    800034a0:	e052                	sd	s4,0(sp)
    800034a2:	1800                	addi	s0,sp,48
    800034a4:	89aa                	mv	s3,a0
    800034a6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034a8:	0001c517          	auipc	a0,0x1c
    800034ac:	52050513          	addi	a0,a0,1312 # 8001f9c8 <itable>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	726080e7          	jalr	1830(ra) # 80000bd6 <acquire>
  empty = 0;
    800034b8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034ba:	0001c497          	auipc	s1,0x1c
    800034be:	52648493          	addi	s1,s1,1318 # 8001f9e0 <itable+0x18>
    800034c2:	0001e697          	auipc	a3,0x1e
    800034c6:	fae68693          	addi	a3,a3,-82 # 80021470 <log>
    800034ca:	a039                	j	800034d8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034cc:	02090b63          	beqz	s2,80003502 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d0:	08848493          	addi	s1,s1,136
    800034d4:	02d48a63          	beq	s1,a3,80003508 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034d8:	449c                	lw	a5,8(s1)
    800034da:	fef059e3          	blez	a5,800034cc <iget+0x38>
    800034de:	4098                	lw	a4,0(s1)
    800034e0:	ff3716e3          	bne	a4,s3,800034cc <iget+0x38>
    800034e4:	40d8                	lw	a4,4(s1)
    800034e6:	ff4713e3          	bne	a4,s4,800034cc <iget+0x38>
      ip->ref++;
    800034ea:	2785                	addiw	a5,a5,1
    800034ec:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034ee:	0001c517          	auipc	a0,0x1c
    800034f2:	4da50513          	addi	a0,a0,1242 # 8001f9c8 <itable>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	794080e7          	jalr	1940(ra) # 80000c8a <release>
      return ip;
    800034fe:	8926                	mv	s2,s1
    80003500:	a03d                	j	8000352e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003502:	f7f9                	bnez	a5,800034d0 <iget+0x3c>
    80003504:	8926                	mv	s2,s1
    80003506:	b7e9                	j	800034d0 <iget+0x3c>
  if(empty == 0)
    80003508:	02090c63          	beqz	s2,80003540 <iget+0xac>
  ip->dev = dev;
    8000350c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003510:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003514:	4785                	li	a5,1
    80003516:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000351a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000351e:	0001c517          	auipc	a0,0x1c
    80003522:	4aa50513          	addi	a0,a0,1194 # 8001f9c8 <itable>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	764080e7          	jalr	1892(ra) # 80000c8a <release>
}
    8000352e:	854a                	mv	a0,s2
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6a02                	ld	s4,0(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    panic("iget: no inodes");
    80003540:	00005517          	auipc	a0,0x5
    80003544:	02850513          	addi	a0,a0,40 # 80008568 <syscalls+0x138>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	fe8080e7          	jalr	-24(ra) # 80000530 <panic>

0000000080003550 <fsinit>:
fsinit(int dev) {
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	e84a                	sd	s2,16(sp)
    8000355a:	e44e                	sd	s3,8(sp)
    8000355c:	1800                	addi	s0,sp,48
    8000355e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003560:	4585                	li	a1,1
    80003562:	00000097          	auipc	ra,0x0
    80003566:	a64080e7          	jalr	-1436(ra) # 80002fc6 <bread>
    8000356a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000356c:	0001c997          	auipc	s3,0x1c
    80003570:	43c98993          	addi	s3,s3,1084 # 8001f9a8 <sb>
    80003574:	02000613          	li	a2,32
    80003578:	05850593          	addi	a1,a0,88
    8000357c:	854e                	mv	a0,s3
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	7b4080e7          	jalr	1972(ra) # 80000d32 <memmove>
  brelse(bp);
    80003586:	8526                	mv	a0,s1
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	b6e080e7          	jalr	-1170(ra) # 800030f6 <brelse>
  if(sb.magic != FSMAGIC)
    80003590:	0009a703          	lw	a4,0(s3)
    80003594:	102037b7          	lui	a5,0x10203
    80003598:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000359c:	02f71263          	bne	a4,a5,800035c0 <fsinit+0x70>
  initlog(dev, &sb);
    800035a0:	0001c597          	auipc	a1,0x1c
    800035a4:	40858593          	addi	a1,a1,1032 # 8001f9a8 <sb>
    800035a8:	854a                	mv	a0,s2
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	b4c080e7          	jalr	-1204(ra) # 800040f6 <initlog>
}
    800035b2:	70a2                	ld	ra,40(sp)
    800035b4:	7402                	ld	s0,32(sp)
    800035b6:	64e2                	ld	s1,24(sp)
    800035b8:	6942                	ld	s2,16(sp)
    800035ba:	69a2                	ld	s3,8(sp)
    800035bc:	6145                	addi	sp,sp,48
    800035be:	8082                	ret
    panic("invalid file system");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	fb850513          	addi	a0,a0,-72 # 80008578 <syscalls+0x148>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f68080e7          	jalr	-152(ra) # 80000530 <panic>

00000000800035d0 <iinit>:
{
    800035d0:	7179                	addi	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	e84a                	sd	s2,16(sp)
    800035da:	e44e                	sd	s3,8(sp)
    800035dc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035de:	00005597          	auipc	a1,0x5
    800035e2:	fb258593          	addi	a1,a1,-78 # 80008590 <syscalls+0x160>
    800035e6:	0001c517          	auipc	a0,0x1c
    800035ea:	3e250513          	addi	a0,a0,994 # 8001f9c8 <itable>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	558080e7          	jalr	1368(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035f6:	0001c497          	auipc	s1,0x1c
    800035fa:	3fa48493          	addi	s1,s1,1018 # 8001f9f0 <itable+0x28>
    800035fe:	0001e997          	auipc	s3,0x1e
    80003602:	e8298993          	addi	s3,s3,-382 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003606:	00005917          	auipc	s2,0x5
    8000360a:	f9290913          	addi	s2,s2,-110 # 80008598 <syscalls+0x168>
    8000360e:	85ca                	mv	a1,s2
    80003610:	8526                	mv	a0,s1
    80003612:	00001097          	auipc	ra,0x1
    80003616:	e46080e7          	jalr	-442(ra) # 80004458 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000361a:	08848493          	addi	s1,s1,136
    8000361e:	ff3498e3          	bne	s1,s3,8000360e <iinit+0x3e>
}
    80003622:	70a2                	ld	ra,40(sp)
    80003624:	7402                	ld	s0,32(sp)
    80003626:	64e2                	ld	s1,24(sp)
    80003628:	6942                	ld	s2,16(sp)
    8000362a:	69a2                	ld	s3,8(sp)
    8000362c:	6145                	addi	sp,sp,48
    8000362e:	8082                	ret

0000000080003630 <ialloc>:
{
    80003630:	715d                	addi	sp,sp,-80
    80003632:	e486                	sd	ra,72(sp)
    80003634:	e0a2                	sd	s0,64(sp)
    80003636:	fc26                	sd	s1,56(sp)
    80003638:	f84a                	sd	s2,48(sp)
    8000363a:	f44e                	sd	s3,40(sp)
    8000363c:	f052                	sd	s4,32(sp)
    8000363e:	ec56                	sd	s5,24(sp)
    80003640:	e85a                	sd	s6,16(sp)
    80003642:	e45e                	sd	s7,8(sp)
    80003644:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003646:	0001c717          	auipc	a4,0x1c
    8000364a:	36e72703          	lw	a4,878(a4) # 8001f9b4 <sb+0xc>
    8000364e:	4785                	li	a5,1
    80003650:	04e7fa63          	bgeu	a5,a4,800036a4 <ialloc+0x74>
    80003654:	8aaa                	mv	s5,a0
    80003656:	8bae                	mv	s7,a1
    80003658:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000365a:	0001ca17          	auipc	s4,0x1c
    8000365e:	34ea0a13          	addi	s4,s4,846 # 8001f9a8 <sb>
    80003662:	00048b1b          	sext.w	s6,s1
    80003666:	0044d593          	srli	a1,s1,0x4
    8000366a:	018a2783          	lw	a5,24(s4)
    8000366e:	9dbd                	addw	a1,a1,a5
    80003670:	8556                	mv	a0,s5
    80003672:	00000097          	auipc	ra,0x0
    80003676:	954080e7          	jalr	-1708(ra) # 80002fc6 <bread>
    8000367a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000367c:	05850993          	addi	s3,a0,88
    80003680:	00f4f793          	andi	a5,s1,15
    80003684:	079a                	slli	a5,a5,0x6
    80003686:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003688:	00099783          	lh	a5,0(s3)
    8000368c:	c785                	beqz	a5,800036b4 <ialloc+0x84>
    brelse(bp);
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	a68080e7          	jalr	-1432(ra) # 800030f6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003696:	0485                	addi	s1,s1,1
    80003698:	00ca2703          	lw	a4,12(s4)
    8000369c:	0004879b          	sext.w	a5,s1
    800036a0:	fce7e1e3          	bltu	a5,a4,80003662 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036a4:	00005517          	auipc	a0,0x5
    800036a8:	efc50513          	addi	a0,a0,-260 # 800085a0 <syscalls+0x170>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	e84080e7          	jalr	-380(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800036b4:	04000613          	li	a2,64
    800036b8:	4581                	li	a1,0
    800036ba:	854e                	mv	a0,s3
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	616080e7          	jalr	1558(ra) # 80000cd2 <memset>
      dip->type = type;
    800036c4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036c8:	854a                	mv	a0,s2
    800036ca:	00001097          	auipc	ra,0x1
    800036ce:	ca8080e7          	jalr	-856(ra) # 80004372 <log_write>
      brelse(bp);
    800036d2:	854a                	mv	a0,s2
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	a22080e7          	jalr	-1502(ra) # 800030f6 <brelse>
      return iget(dev, inum);
    800036dc:	85da                	mv	a1,s6
    800036de:	8556                	mv	a0,s5
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	db4080e7          	jalr	-588(ra) # 80003494 <iget>
}
    800036e8:	60a6                	ld	ra,72(sp)
    800036ea:	6406                	ld	s0,64(sp)
    800036ec:	74e2                	ld	s1,56(sp)
    800036ee:	7942                	ld	s2,48(sp)
    800036f0:	79a2                	ld	s3,40(sp)
    800036f2:	7a02                	ld	s4,32(sp)
    800036f4:	6ae2                	ld	s5,24(sp)
    800036f6:	6b42                	ld	s6,16(sp)
    800036f8:	6ba2                	ld	s7,8(sp)
    800036fa:	6161                	addi	sp,sp,80
    800036fc:	8082                	ret

00000000800036fe <iupdate>:
{
    800036fe:	1101                	addi	sp,sp,-32
    80003700:	ec06                	sd	ra,24(sp)
    80003702:	e822                	sd	s0,16(sp)
    80003704:	e426                	sd	s1,8(sp)
    80003706:	e04a                	sd	s2,0(sp)
    80003708:	1000                	addi	s0,sp,32
    8000370a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000370c:	415c                	lw	a5,4(a0)
    8000370e:	0047d79b          	srliw	a5,a5,0x4
    80003712:	0001c597          	auipc	a1,0x1c
    80003716:	2ae5a583          	lw	a1,686(a1) # 8001f9c0 <sb+0x18>
    8000371a:	9dbd                	addw	a1,a1,a5
    8000371c:	4108                	lw	a0,0(a0)
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	8a8080e7          	jalr	-1880(ra) # 80002fc6 <bread>
    80003726:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003728:	05850793          	addi	a5,a0,88
    8000372c:	40c8                	lw	a0,4(s1)
    8000372e:	893d                	andi	a0,a0,15
    80003730:	051a                	slli	a0,a0,0x6
    80003732:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003734:	04449703          	lh	a4,68(s1)
    80003738:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000373c:	04649703          	lh	a4,70(s1)
    80003740:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003744:	04849703          	lh	a4,72(s1)
    80003748:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000374c:	04a49703          	lh	a4,74(s1)
    80003750:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003754:	44f8                	lw	a4,76(s1)
    80003756:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003758:	03400613          	li	a2,52
    8000375c:	05048593          	addi	a1,s1,80
    80003760:	0531                	addi	a0,a0,12
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	5d0080e7          	jalr	1488(ra) # 80000d32 <memmove>
  log_write(bp);
    8000376a:	854a                	mv	a0,s2
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	c06080e7          	jalr	-1018(ra) # 80004372 <log_write>
  brelse(bp);
    80003774:	854a                	mv	a0,s2
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	980080e7          	jalr	-1664(ra) # 800030f6 <brelse>
}
    8000377e:	60e2                	ld	ra,24(sp)
    80003780:	6442                	ld	s0,16(sp)
    80003782:	64a2                	ld	s1,8(sp)
    80003784:	6902                	ld	s2,0(sp)
    80003786:	6105                	addi	sp,sp,32
    80003788:	8082                	ret

000000008000378a <idup>:
{
    8000378a:	1101                	addi	sp,sp,-32
    8000378c:	ec06                	sd	ra,24(sp)
    8000378e:	e822                	sd	s0,16(sp)
    80003790:	e426                	sd	s1,8(sp)
    80003792:	1000                	addi	s0,sp,32
    80003794:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003796:	0001c517          	auipc	a0,0x1c
    8000379a:	23250513          	addi	a0,a0,562 # 8001f9c8 <itable>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	438080e7          	jalr	1080(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037a6:	449c                	lw	a5,8(s1)
    800037a8:	2785                	addiw	a5,a5,1
    800037aa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037ac:	0001c517          	auipc	a0,0x1c
    800037b0:	21c50513          	addi	a0,a0,540 # 8001f9c8 <itable>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	4d6080e7          	jalr	1238(ra) # 80000c8a <release>
}
    800037bc:	8526                	mv	a0,s1
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6105                	addi	sp,sp,32
    800037c6:	8082                	ret

00000000800037c8 <ilock>:
{
    800037c8:	1101                	addi	sp,sp,-32
    800037ca:	ec06                	sd	ra,24(sp)
    800037cc:	e822                	sd	s0,16(sp)
    800037ce:	e426                	sd	s1,8(sp)
    800037d0:	e04a                	sd	s2,0(sp)
    800037d2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037d4:	c115                	beqz	a0,800037f8 <ilock+0x30>
    800037d6:	84aa                	mv	s1,a0
    800037d8:	451c                	lw	a5,8(a0)
    800037da:	00f05f63          	blez	a5,800037f8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037de:	0541                	addi	a0,a0,16
    800037e0:	00001097          	auipc	ra,0x1
    800037e4:	cb2080e7          	jalr	-846(ra) # 80004492 <acquiresleep>
  if(ip->valid == 0){
    800037e8:	40bc                	lw	a5,64(s1)
    800037ea:	cf99                	beqz	a5,80003808 <ilock+0x40>
}
    800037ec:	60e2                	ld	ra,24(sp)
    800037ee:	6442                	ld	s0,16(sp)
    800037f0:	64a2                	ld	s1,8(sp)
    800037f2:	6902                	ld	s2,0(sp)
    800037f4:	6105                	addi	sp,sp,32
    800037f6:	8082                	ret
    panic("ilock");
    800037f8:	00005517          	auipc	a0,0x5
    800037fc:	dc050513          	addi	a0,a0,-576 # 800085b8 <syscalls+0x188>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	d30080e7          	jalr	-720(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003808:	40dc                	lw	a5,4(s1)
    8000380a:	0047d79b          	srliw	a5,a5,0x4
    8000380e:	0001c597          	auipc	a1,0x1c
    80003812:	1b25a583          	lw	a1,434(a1) # 8001f9c0 <sb+0x18>
    80003816:	9dbd                	addw	a1,a1,a5
    80003818:	4088                	lw	a0,0(s1)
    8000381a:	fffff097          	auipc	ra,0xfffff
    8000381e:	7ac080e7          	jalr	1964(ra) # 80002fc6 <bread>
    80003822:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003824:	05850593          	addi	a1,a0,88
    80003828:	40dc                	lw	a5,4(s1)
    8000382a:	8bbd                	andi	a5,a5,15
    8000382c:	079a                	slli	a5,a5,0x6
    8000382e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003830:	00059783          	lh	a5,0(a1)
    80003834:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003838:	00259783          	lh	a5,2(a1)
    8000383c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003840:	00459783          	lh	a5,4(a1)
    80003844:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003848:	00659783          	lh	a5,6(a1)
    8000384c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003850:	459c                	lw	a5,8(a1)
    80003852:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003854:	03400613          	li	a2,52
    80003858:	05b1                	addi	a1,a1,12
    8000385a:	05048513          	addi	a0,s1,80
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	4d4080e7          	jalr	1236(ra) # 80000d32 <memmove>
    brelse(bp);
    80003866:	854a                	mv	a0,s2
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	88e080e7          	jalr	-1906(ra) # 800030f6 <brelse>
    ip->valid = 1;
    80003870:	4785                	li	a5,1
    80003872:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003874:	04449783          	lh	a5,68(s1)
    80003878:	fbb5                	bnez	a5,800037ec <ilock+0x24>
      panic("ilock: no type");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	d4650513          	addi	a0,a0,-698 # 800085c0 <syscalls+0x190>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cae080e7          	jalr	-850(ra) # 80000530 <panic>

000000008000388a <iunlock>:
{
    8000388a:	1101                	addi	sp,sp,-32
    8000388c:	ec06                	sd	ra,24(sp)
    8000388e:	e822                	sd	s0,16(sp)
    80003890:	e426                	sd	s1,8(sp)
    80003892:	e04a                	sd	s2,0(sp)
    80003894:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003896:	c905                	beqz	a0,800038c6 <iunlock+0x3c>
    80003898:	84aa                	mv	s1,a0
    8000389a:	01050913          	addi	s2,a0,16
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	c8c080e7          	jalr	-884(ra) # 8000452c <holdingsleep>
    800038a8:	cd19                	beqz	a0,800038c6 <iunlock+0x3c>
    800038aa:	449c                	lw	a5,8(s1)
    800038ac:	00f05d63          	blez	a5,800038c6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b0:	854a                	mv	a0,s2
    800038b2:	00001097          	auipc	ra,0x1
    800038b6:	c36080e7          	jalr	-970(ra) # 800044e8 <releasesleep>
}
    800038ba:	60e2                	ld	ra,24(sp)
    800038bc:	6442                	ld	s0,16(sp)
    800038be:	64a2                	ld	s1,8(sp)
    800038c0:	6902                	ld	s2,0(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret
    panic("iunlock");
    800038c6:	00005517          	auipc	a0,0x5
    800038ca:	d0a50513          	addi	a0,a0,-758 # 800085d0 <syscalls+0x1a0>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	c62080e7          	jalr	-926(ra) # 80000530 <panic>

00000000800038d6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038d6:	7179                	addi	sp,sp,-48
    800038d8:	f406                	sd	ra,40(sp)
    800038da:	f022                	sd	s0,32(sp)
    800038dc:	ec26                	sd	s1,24(sp)
    800038de:	e84a                	sd	s2,16(sp)
    800038e0:	e44e                	sd	s3,8(sp)
    800038e2:	e052                	sd	s4,0(sp)
    800038e4:	1800                	addi	s0,sp,48
    800038e6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038e8:	05050493          	addi	s1,a0,80
    800038ec:	08050913          	addi	s2,a0,128
    800038f0:	a021                	j	800038f8 <itrunc+0x22>
    800038f2:	0491                	addi	s1,s1,4
    800038f4:	01248d63          	beq	s1,s2,8000390e <itrunc+0x38>
    if(ip->addrs[i]){
    800038f8:	408c                	lw	a1,0(s1)
    800038fa:	dde5                	beqz	a1,800038f2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038fc:	0009a503          	lw	a0,0(s3)
    80003900:	00000097          	auipc	ra,0x0
    80003904:	90c080e7          	jalr	-1780(ra) # 8000320c <bfree>
      ip->addrs[i] = 0;
    80003908:	0004a023          	sw	zero,0(s1)
    8000390c:	b7dd                	j	800038f2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000390e:	0809a583          	lw	a1,128(s3)
    80003912:	e185                	bnez	a1,80003932 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003914:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003918:	854e                	mv	a0,s3
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	de4080e7          	jalr	-540(ra) # 800036fe <iupdate>
}
    80003922:	70a2                	ld	ra,40(sp)
    80003924:	7402                	ld	s0,32(sp)
    80003926:	64e2                	ld	s1,24(sp)
    80003928:	6942                	ld	s2,16(sp)
    8000392a:	69a2                	ld	s3,8(sp)
    8000392c:	6a02                	ld	s4,0(sp)
    8000392e:	6145                	addi	sp,sp,48
    80003930:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003932:	0009a503          	lw	a0,0(s3)
    80003936:	fffff097          	auipc	ra,0xfffff
    8000393a:	690080e7          	jalr	1680(ra) # 80002fc6 <bread>
    8000393e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003940:	05850493          	addi	s1,a0,88
    80003944:	45850913          	addi	s2,a0,1112
    80003948:	a811                	j	8000395c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000394a:	0009a503          	lw	a0,0(s3)
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	8be080e7          	jalr	-1858(ra) # 8000320c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003956:	0491                	addi	s1,s1,4
    80003958:	01248563          	beq	s1,s2,80003962 <itrunc+0x8c>
      if(a[j])
    8000395c:	408c                	lw	a1,0(s1)
    8000395e:	dde5                	beqz	a1,80003956 <itrunc+0x80>
    80003960:	b7ed                	j	8000394a <itrunc+0x74>
    brelse(bp);
    80003962:	8552                	mv	a0,s4
    80003964:	fffff097          	auipc	ra,0xfffff
    80003968:	792080e7          	jalr	1938(ra) # 800030f6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000396c:	0809a583          	lw	a1,128(s3)
    80003970:	0009a503          	lw	a0,0(s3)
    80003974:	00000097          	auipc	ra,0x0
    80003978:	898080e7          	jalr	-1896(ra) # 8000320c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000397c:	0809a023          	sw	zero,128(s3)
    80003980:	bf51                	j	80003914 <itrunc+0x3e>

0000000080003982 <iput>:
{
    80003982:	1101                	addi	sp,sp,-32
    80003984:	ec06                	sd	ra,24(sp)
    80003986:	e822                	sd	s0,16(sp)
    80003988:	e426                	sd	s1,8(sp)
    8000398a:	e04a                	sd	s2,0(sp)
    8000398c:	1000                	addi	s0,sp,32
    8000398e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003990:	0001c517          	auipc	a0,0x1c
    80003994:	03850513          	addi	a0,a0,56 # 8001f9c8 <itable>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	23e080e7          	jalr	574(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a0:	4498                	lw	a4,8(s1)
    800039a2:	4785                	li	a5,1
    800039a4:	02f70363          	beq	a4,a5,800039ca <iput+0x48>
  ip->ref--;
    800039a8:	449c                	lw	a5,8(s1)
    800039aa:	37fd                	addiw	a5,a5,-1
    800039ac:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ae:	0001c517          	auipc	a0,0x1c
    800039b2:	01a50513          	addi	a0,a0,26 # 8001f9c8 <itable>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	2d4080e7          	jalr	724(ra) # 80000c8a <release>
}
    800039be:	60e2                	ld	ra,24(sp)
    800039c0:	6442                	ld	s0,16(sp)
    800039c2:	64a2                	ld	s1,8(sp)
    800039c4:	6902                	ld	s2,0(sp)
    800039c6:	6105                	addi	sp,sp,32
    800039c8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ca:	40bc                	lw	a5,64(s1)
    800039cc:	dff1                	beqz	a5,800039a8 <iput+0x26>
    800039ce:	04a49783          	lh	a5,74(s1)
    800039d2:	fbf9                	bnez	a5,800039a8 <iput+0x26>
    acquiresleep(&ip->lock);
    800039d4:	01048913          	addi	s2,s1,16
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	ab8080e7          	jalr	-1352(ra) # 80004492 <acquiresleep>
    release(&itable.lock);
    800039e2:	0001c517          	auipc	a0,0x1c
    800039e6:	fe650513          	addi	a0,a0,-26 # 8001f9c8 <itable>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	2a0080e7          	jalr	672(ra) # 80000c8a <release>
    itrunc(ip);
    800039f2:	8526                	mv	a0,s1
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	ee2080e7          	jalr	-286(ra) # 800038d6 <itrunc>
    ip->type = 0;
    800039fc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a00:	8526                	mv	a0,s1
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	cfc080e7          	jalr	-772(ra) # 800036fe <iupdate>
    ip->valid = 0;
    80003a0a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	ad8080e7          	jalr	-1320(ra) # 800044e8 <releasesleep>
    acquire(&itable.lock);
    80003a18:	0001c517          	auipc	a0,0x1c
    80003a1c:	fb050513          	addi	a0,a0,-80 # 8001f9c8 <itable>
    80003a20:	ffffd097          	auipc	ra,0xffffd
    80003a24:	1b6080e7          	jalr	438(ra) # 80000bd6 <acquire>
    80003a28:	b741                	j	800039a8 <iput+0x26>

0000000080003a2a <iunlockput>:
{
    80003a2a:	1101                	addi	sp,sp,-32
    80003a2c:	ec06                	sd	ra,24(sp)
    80003a2e:	e822                	sd	s0,16(sp)
    80003a30:	e426                	sd	s1,8(sp)
    80003a32:	1000                	addi	s0,sp,32
    80003a34:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	e54080e7          	jalr	-428(ra) # 8000388a <iunlock>
  iput(ip);
    80003a3e:	8526                	mv	a0,s1
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	f42080e7          	jalr	-190(ra) # 80003982 <iput>
}
    80003a48:	60e2                	ld	ra,24(sp)
    80003a4a:	6442                	ld	s0,16(sp)
    80003a4c:	64a2                	ld	s1,8(sp)
    80003a4e:	6105                	addi	sp,sp,32
    80003a50:	8082                	ret

0000000080003a52 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a52:	1141                	addi	sp,sp,-16
    80003a54:	e422                	sd	s0,8(sp)
    80003a56:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a58:	411c                	lw	a5,0(a0)
    80003a5a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a5c:	415c                	lw	a5,4(a0)
    80003a5e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a60:	04451783          	lh	a5,68(a0)
    80003a64:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a68:	04a51783          	lh	a5,74(a0)
    80003a6c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a70:	04c56783          	lwu	a5,76(a0)
    80003a74:	e99c                	sd	a5,16(a1)
}
    80003a76:	6422                	ld	s0,8(sp)
    80003a78:	0141                	addi	sp,sp,16
    80003a7a:	8082                	ret

0000000080003a7c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a7c:	457c                	lw	a5,76(a0)
    80003a7e:	0ed7e963          	bltu	a5,a3,80003b70 <readi+0xf4>
{
    80003a82:	7159                	addi	sp,sp,-112
    80003a84:	f486                	sd	ra,104(sp)
    80003a86:	f0a2                	sd	s0,96(sp)
    80003a88:	eca6                	sd	s1,88(sp)
    80003a8a:	e8ca                	sd	s2,80(sp)
    80003a8c:	e4ce                	sd	s3,72(sp)
    80003a8e:	e0d2                	sd	s4,64(sp)
    80003a90:	fc56                	sd	s5,56(sp)
    80003a92:	f85a                	sd	s6,48(sp)
    80003a94:	f45e                	sd	s7,40(sp)
    80003a96:	f062                	sd	s8,32(sp)
    80003a98:	ec66                	sd	s9,24(sp)
    80003a9a:	e86a                	sd	s10,16(sp)
    80003a9c:	e46e                	sd	s11,8(sp)
    80003a9e:	1880                	addi	s0,sp,112
    80003aa0:	8baa                	mv	s7,a0
    80003aa2:	8c2e                	mv	s8,a1
    80003aa4:	8ab2                	mv	s5,a2
    80003aa6:	84b6                	mv	s1,a3
    80003aa8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aaa:	9f35                	addw	a4,a4,a3
    return 0;
    80003aac:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aae:	0ad76063          	bltu	a4,a3,80003b4e <readi+0xd2>
  if(off + n > ip->size)
    80003ab2:	00e7f463          	bgeu	a5,a4,80003aba <readi+0x3e>
    n = ip->size - off;
    80003ab6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aba:	0a0b0963          	beqz	s6,80003b6c <readi+0xf0>
    80003abe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ac4:	5cfd                	li	s9,-1
    80003ac6:	a82d                	j	80003b00 <readi+0x84>
    80003ac8:	020a1d93          	slli	s11,s4,0x20
    80003acc:	020ddd93          	srli	s11,s11,0x20
    80003ad0:	05890613          	addi	a2,s2,88
    80003ad4:	86ee                	mv	a3,s11
    80003ad6:	963a                	add	a2,a2,a4
    80003ad8:	85d6                	mv	a1,s5
    80003ada:	8562                	mv	a0,s8
    80003adc:	fffff097          	auipc	ra,0xfffff
    80003ae0:	984080e7          	jalr	-1660(ra) # 80002460 <either_copyout>
    80003ae4:	05950d63          	beq	a0,s9,80003b3e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ae8:	854a                	mv	a0,s2
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	60c080e7          	jalr	1548(ra) # 800030f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af2:	013a09bb          	addw	s3,s4,s3
    80003af6:	009a04bb          	addw	s1,s4,s1
    80003afa:	9aee                	add	s5,s5,s11
    80003afc:	0569f763          	bgeu	s3,s6,80003b4a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b00:	000ba903          	lw	s2,0(s7)
    80003b04:	00a4d59b          	srliw	a1,s1,0xa
    80003b08:	855e                	mv	a0,s7
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	8b0080e7          	jalr	-1872(ra) # 800033ba <bmap>
    80003b12:	0005059b          	sext.w	a1,a0
    80003b16:	854a                	mv	a0,s2
    80003b18:	fffff097          	auipc	ra,0xfffff
    80003b1c:	4ae080e7          	jalr	1198(ra) # 80002fc6 <bread>
    80003b20:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b22:	3ff4f713          	andi	a4,s1,1023
    80003b26:	40ed07bb          	subw	a5,s10,a4
    80003b2a:	413b06bb          	subw	a3,s6,s3
    80003b2e:	8a3e                	mv	s4,a5
    80003b30:	2781                	sext.w	a5,a5
    80003b32:	0006861b          	sext.w	a2,a3
    80003b36:	f8f679e3          	bgeu	a2,a5,80003ac8 <readi+0x4c>
    80003b3a:	8a36                	mv	s4,a3
    80003b3c:	b771                	j	80003ac8 <readi+0x4c>
      brelse(bp);
    80003b3e:	854a                	mv	a0,s2
    80003b40:	fffff097          	auipc	ra,0xfffff
    80003b44:	5b6080e7          	jalr	1462(ra) # 800030f6 <brelse>
      tot = -1;
    80003b48:	59fd                	li	s3,-1
  }
  return tot;
    80003b4a:	0009851b          	sext.w	a0,s3
}
    80003b4e:	70a6                	ld	ra,104(sp)
    80003b50:	7406                	ld	s0,96(sp)
    80003b52:	64e6                	ld	s1,88(sp)
    80003b54:	6946                	ld	s2,80(sp)
    80003b56:	69a6                	ld	s3,72(sp)
    80003b58:	6a06                	ld	s4,64(sp)
    80003b5a:	7ae2                	ld	s5,56(sp)
    80003b5c:	7b42                	ld	s6,48(sp)
    80003b5e:	7ba2                	ld	s7,40(sp)
    80003b60:	7c02                	ld	s8,32(sp)
    80003b62:	6ce2                	ld	s9,24(sp)
    80003b64:	6d42                	ld	s10,16(sp)
    80003b66:	6da2                	ld	s11,8(sp)
    80003b68:	6165                	addi	sp,sp,112
    80003b6a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6c:	89da                	mv	s3,s6
    80003b6e:	bff1                	j	80003b4a <readi+0xce>
    return 0;
    80003b70:	4501                	li	a0,0
}
    80003b72:	8082                	ret

0000000080003b74 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b74:	457c                	lw	a5,76(a0)
    80003b76:	10d7e863          	bltu	a5,a3,80003c86 <writei+0x112>
{
    80003b7a:	7159                	addi	sp,sp,-112
    80003b7c:	f486                	sd	ra,104(sp)
    80003b7e:	f0a2                	sd	s0,96(sp)
    80003b80:	eca6                	sd	s1,88(sp)
    80003b82:	e8ca                	sd	s2,80(sp)
    80003b84:	e4ce                	sd	s3,72(sp)
    80003b86:	e0d2                	sd	s4,64(sp)
    80003b88:	fc56                	sd	s5,56(sp)
    80003b8a:	f85a                	sd	s6,48(sp)
    80003b8c:	f45e                	sd	s7,40(sp)
    80003b8e:	f062                	sd	s8,32(sp)
    80003b90:	ec66                	sd	s9,24(sp)
    80003b92:	e86a                	sd	s10,16(sp)
    80003b94:	e46e                	sd	s11,8(sp)
    80003b96:	1880                	addi	s0,sp,112
    80003b98:	8b2a                	mv	s6,a0
    80003b9a:	8c2e                	mv	s8,a1
    80003b9c:	8ab2                	mv	s5,a2
    80003b9e:	8936                	mv	s2,a3
    80003ba0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ba2:	00e687bb          	addw	a5,a3,a4
    80003ba6:	0ed7e263          	bltu	a5,a3,80003c8a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003baa:	00043737          	lui	a4,0x43
    80003bae:	0ef76063          	bltu	a4,a5,80003c8e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb2:	0c0b8863          	beqz	s7,80003c82 <writei+0x10e>
    80003bb6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bbc:	5cfd                	li	s9,-1
    80003bbe:	a091                	j	80003c02 <writei+0x8e>
    80003bc0:	02099d93          	slli	s11,s3,0x20
    80003bc4:	020ddd93          	srli	s11,s11,0x20
    80003bc8:	05848513          	addi	a0,s1,88
    80003bcc:	86ee                	mv	a3,s11
    80003bce:	8656                	mv	a2,s5
    80003bd0:	85e2                	mv	a1,s8
    80003bd2:	953a                	add	a0,a0,a4
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	8e2080e7          	jalr	-1822(ra) # 800024b6 <either_copyin>
    80003bdc:	07950263          	beq	a0,s9,80003c40 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be0:	8526                	mv	a0,s1
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	790080e7          	jalr	1936(ra) # 80004372 <log_write>
    brelse(bp);
    80003bea:	8526                	mv	a0,s1
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	50a080e7          	jalr	1290(ra) # 800030f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf4:	01498a3b          	addw	s4,s3,s4
    80003bf8:	0129893b          	addw	s2,s3,s2
    80003bfc:	9aee                	add	s5,s5,s11
    80003bfe:	057a7663          	bgeu	s4,s7,80003c4a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c02:	000b2483          	lw	s1,0(s6)
    80003c06:	00a9559b          	srliw	a1,s2,0xa
    80003c0a:	855a                	mv	a0,s6
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	7ae080e7          	jalr	1966(ra) # 800033ba <bmap>
    80003c14:	0005059b          	sext.w	a1,a0
    80003c18:	8526                	mv	a0,s1
    80003c1a:	fffff097          	auipc	ra,0xfffff
    80003c1e:	3ac080e7          	jalr	940(ra) # 80002fc6 <bread>
    80003c22:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c24:	3ff97713          	andi	a4,s2,1023
    80003c28:	40ed07bb          	subw	a5,s10,a4
    80003c2c:	414b86bb          	subw	a3,s7,s4
    80003c30:	89be                	mv	s3,a5
    80003c32:	2781                	sext.w	a5,a5
    80003c34:	0006861b          	sext.w	a2,a3
    80003c38:	f8f674e3          	bgeu	a2,a5,80003bc0 <writei+0x4c>
    80003c3c:	89b6                	mv	s3,a3
    80003c3e:	b749                	j	80003bc0 <writei+0x4c>
      brelse(bp);
    80003c40:	8526                	mv	a0,s1
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	4b4080e7          	jalr	1204(ra) # 800030f6 <brelse>
  }

  if(off > ip->size)
    80003c4a:	04cb2783          	lw	a5,76(s6)
    80003c4e:	0127f463          	bgeu	a5,s2,80003c56 <writei+0xe2>
    ip->size = off;
    80003c52:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c56:	855a                	mv	a0,s6
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	aa6080e7          	jalr	-1370(ra) # 800036fe <iupdate>

  return tot;
    80003c60:	000a051b          	sext.w	a0,s4
}
    80003c64:	70a6                	ld	ra,104(sp)
    80003c66:	7406                	ld	s0,96(sp)
    80003c68:	64e6                	ld	s1,88(sp)
    80003c6a:	6946                	ld	s2,80(sp)
    80003c6c:	69a6                	ld	s3,72(sp)
    80003c6e:	6a06                	ld	s4,64(sp)
    80003c70:	7ae2                	ld	s5,56(sp)
    80003c72:	7b42                	ld	s6,48(sp)
    80003c74:	7ba2                	ld	s7,40(sp)
    80003c76:	7c02                	ld	s8,32(sp)
    80003c78:	6ce2                	ld	s9,24(sp)
    80003c7a:	6d42                	ld	s10,16(sp)
    80003c7c:	6da2                	ld	s11,8(sp)
    80003c7e:	6165                	addi	sp,sp,112
    80003c80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c82:	8a5e                	mv	s4,s7
    80003c84:	bfc9                	j	80003c56 <writei+0xe2>
    return -1;
    80003c86:	557d                	li	a0,-1
}
    80003c88:	8082                	ret
    return -1;
    80003c8a:	557d                	li	a0,-1
    80003c8c:	bfe1                	j	80003c64 <writei+0xf0>
    return -1;
    80003c8e:	557d                	li	a0,-1
    80003c90:	bfd1                	j	80003c64 <writei+0xf0>

0000000080003c92 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c92:	1141                	addi	sp,sp,-16
    80003c94:	e406                	sd	ra,8(sp)
    80003c96:	e022                	sd	s0,0(sp)
    80003c98:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c9a:	4639                	li	a2,14
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	112080e7          	jalr	274(ra) # 80000dae <strncmp>
}
    80003ca4:	60a2                	ld	ra,8(sp)
    80003ca6:	6402                	ld	s0,0(sp)
    80003ca8:	0141                	addi	sp,sp,16
    80003caa:	8082                	ret

0000000080003cac <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cac:	7139                	addi	sp,sp,-64
    80003cae:	fc06                	sd	ra,56(sp)
    80003cb0:	f822                	sd	s0,48(sp)
    80003cb2:	f426                	sd	s1,40(sp)
    80003cb4:	f04a                	sd	s2,32(sp)
    80003cb6:	ec4e                	sd	s3,24(sp)
    80003cb8:	e852                	sd	s4,16(sp)
    80003cba:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cbc:	04451703          	lh	a4,68(a0)
    80003cc0:	4785                	li	a5,1
    80003cc2:	00f71a63          	bne	a4,a5,80003cd6 <dirlookup+0x2a>
    80003cc6:	892a                	mv	s2,a0
    80003cc8:	89ae                	mv	s3,a1
    80003cca:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ccc:	457c                	lw	a5,76(a0)
    80003cce:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd2:	e79d                	bnez	a5,80003d00 <dirlookup+0x54>
    80003cd4:	a8a5                	j	80003d4c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cd6:	00005517          	auipc	a0,0x5
    80003cda:	90250513          	addi	a0,a0,-1790 # 800085d8 <syscalls+0x1a8>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	852080e7          	jalr	-1966(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003ce6:	00005517          	auipc	a0,0x5
    80003cea:	90a50513          	addi	a0,a0,-1782 # 800085f0 <syscalls+0x1c0>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	842080e7          	jalr	-1982(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf6:	24c1                	addiw	s1,s1,16
    80003cf8:	04c92783          	lw	a5,76(s2)
    80003cfc:	04f4f763          	bgeu	s1,a5,80003d4a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d00:	4741                	li	a4,16
    80003d02:	86a6                	mv	a3,s1
    80003d04:	fc040613          	addi	a2,s0,-64
    80003d08:	4581                	li	a1,0
    80003d0a:	854a                	mv	a0,s2
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	d70080e7          	jalr	-656(ra) # 80003a7c <readi>
    80003d14:	47c1                	li	a5,16
    80003d16:	fcf518e3          	bne	a0,a5,80003ce6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d1a:	fc045783          	lhu	a5,-64(s0)
    80003d1e:	dfe1                	beqz	a5,80003cf6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d20:	fc240593          	addi	a1,s0,-62
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	f6c080e7          	jalr	-148(ra) # 80003c92 <namecmp>
    80003d2e:	f561                	bnez	a0,80003cf6 <dirlookup+0x4a>
      if(poff)
    80003d30:	000a0463          	beqz	s4,80003d38 <dirlookup+0x8c>
        *poff = off;
    80003d34:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d38:	fc045583          	lhu	a1,-64(s0)
    80003d3c:	00092503          	lw	a0,0(s2)
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	754080e7          	jalr	1876(ra) # 80003494 <iget>
    80003d48:	a011                	j	80003d4c <dirlookup+0xa0>
  return 0;
    80003d4a:	4501                	li	a0,0
}
    80003d4c:	70e2                	ld	ra,56(sp)
    80003d4e:	7442                	ld	s0,48(sp)
    80003d50:	74a2                	ld	s1,40(sp)
    80003d52:	7902                	ld	s2,32(sp)
    80003d54:	69e2                	ld	s3,24(sp)
    80003d56:	6a42                	ld	s4,16(sp)
    80003d58:	6121                	addi	sp,sp,64
    80003d5a:	8082                	ret

0000000080003d5c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d5c:	711d                	addi	sp,sp,-96
    80003d5e:	ec86                	sd	ra,88(sp)
    80003d60:	e8a2                	sd	s0,80(sp)
    80003d62:	e4a6                	sd	s1,72(sp)
    80003d64:	e0ca                	sd	s2,64(sp)
    80003d66:	fc4e                	sd	s3,56(sp)
    80003d68:	f852                	sd	s4,48(sp)
    80003d6a:	f456                	sd	s5,40(sp)
    80003d6c:	f05a                	sd	s6,32(sp)
    80003d6e:	ec5e                	sd	s7,24(sp)
    80003d70:	e862                	sd	s8,16(sp)
    80003d72:	e466                	sd	s9,8(sp)
    80003d74:	1080                	addi	s0,sp,96
    80003d76:	84aa                	mv	s1,a0
    80003d78:	8b2e                	mv	s6,a1
    80003d7a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d7c:	00054703          	lbu	a4,0(a0)
    80003d80:	02f00793          	li	a5,47
    80003d84:	02f70363          	beq	a4,a5,80003daa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d88:	ffffe097          	auipc	ra,0xffffe
    80003d8c:	c0c080e7          	jalr	-1012(ra) # 80001994 <myproc>
    80003d90:	15053503          	ld	a0,336(a0)
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	9f6080e7          	jalr	-1546(ra) # 8000378a <idup>
    80003d9c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d9e:	02f00913          	li	s2,47
  len = path - s;
    80003da2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003da4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003da6:	4c05                	li	s8,1
    80003da8:	a865                	j	80003e60 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003daa:	4585                	li	a1,1
    80003dac:	4505                	li	a0,1
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	6e6080e7          	jalr	1766(ra) # 80003494 <iget>
    80003db6:	89aa                	mv	s3,a0
    80003db8:	b7dd                	j	80003d9e <namex+0x42>
      iunlockput(ip);
    80003dba:	854e                	mv	a0,s3
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	c6e080e7          	jalr	-914(ra) # 80003a2a <iunlockput>
      return 0;
    80003dc4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc6:	854e                	mv	a0,s3
    80003dc8:	60e6                	ld	ra,88(sp)
    80003dca:	6446                	ld	s0,80(sp)
    80003dcc:	64a6                	ld	s1,72(sp)
    80003dce:	6906                	ld	s2,64(sp)
    80003dd0:	79e2                	ld	s3,56(sp)
    80003dd2:	7a42                	ld	s4,48(sp)
    80003dd4:	7aa2                	ld	s5,40(sp)
    80003dd6:	7b02                	ld	s6,32(sp)
    80003dd8:	6be2                	ld	s7,24(sp)
    80003dda:	6c42                	ld	s8,16(sp)
    80003ddc:	6ca2                	ld	s9,8(sp)
    80003dde:	6125                	addi	sp,sp,96
    80003de0:	8082                	ret
      iunlock(ip);
    80003de2:	854e                	mv	a0,s3
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	aa6080e7          	jalr	-1370(ra) # 8000388a <iunlock>
      return ip;
    80003dec:	bfe9                	j	80003dc6 <namex+0x6a>
      iunlockput(ip);
    80003dee:	854e                	mv	a0,s3
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	c3a080e7          	jalr	-966(ra) # 80003a2a <iunlockput>
      return 0;
    80003df8:	89d2                	mv	s3,s4
    80003dfa:	b7f1                	j	80003dc6 <namex+0x6a>
  len = path - s;
    80003dfc:	40b48633          	sub	a2,s1,a1
    80003e00:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e04:	094cd463          	bge	s9,s4,80003e8c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e08:	4639                	li	a2,14
    80003e0a:	8556                	mv	a0,s5
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	f26080e7          	jalr	-218(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003e14:	0004c783          	lbu	a5,0(s1)
    80003e18:	01279763          	bne	a5,s2,80003e26 <namex+0xca>
    path++;
    80003e1c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e1e:	0004c783          	lbu	a5,0(s1)
    80003e22:	ff278de3          	beq	a5,s2,80003e1c <namex+0xc0>
    ilock(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	9a0080e7          	jalr	-1632(ra) # 800037c8 <ilock>
    if(ip->type != T_DIR){
    80003e30:	04499783          	lh	a5,68(s3)
    80003e34:	f98793e3          	bne	a5,s8,80003dba <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e38:	000b0563          	beqz	s6,80003e42 <namex+0xe6>
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	d3cd                	beqz	a5,80003de2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e42:	865e                	mv	a2,s7
    80003e44:	85d6                	mv	a1,s5
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	e64080e7          	jalr	-412(ra) # 80003cac <dirlookup>
    80003e50:	8a2a                	mv	s4,a0
    80003e52:	dd51                	beqz	a0,80003dee <namex+0x92>
    iunlockput(ip);
    80003e54:	854e                	mv	a0,s3
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	bd4080e7          	jalr	-1068(ra) # 80003a2a <iunlockput>
    ip = next;
    80003e5e:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e60:	0004c783          	lbu	a5,0(s1)
    80003e64:	05279763          	bne	a5,s2,80003eb2 <namex+0x156>
    path++;
    80003e68:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e6a:	0004c783          	lbu	a5,0(s1)
    80003e6e:	ff278de3          	beq	a5,s2,80003e68 <namex+0x10c>
  if(*path == 0)
    80003e72:	c79d                	beqz	a5,80003ea0 <namex+0x144>
    path++;
    80003e74:	85a6                	mv	a1,s1
  len = path - s;
    80003e76:	8a5e                	mv	s4,s7
    80003e78:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e7a:	01278963          	beq	a5,s2,80003e8c <namex+0x130>
    80003e7e:	dfbd                	beqz	a5,80003dfc <namex+0xa0>
    path++;
    80003e80:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e82:	0004c783          	lbu	a5,0(s1)
    80003e86:	ff279ce3          	bne	a5,s2,80003e7e <namex+0x122>
    80003e8a:	bf8d                	j	80003dfc <namex+0xa0>
    memmove(name, s, len);
    80003e8c:	2601                	sext.w	a2,a2
    80003e8e:	8556                	mv	a0,s5
    80003e90:	ffffd097          	auipc	ra,0xffffd
    80003e94:	ea2080e7          	jalr	-350(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003e98:	9a56                	add	s4,s4,s5
    80003e9a:	000a0023          	sb	zero,0(s4)
    80003e9e:	bf9d                	j	80003e14 <namex+0xb8>
  if(nameiparent){
    80003ea0:	f20b03e3          	beqz	s6,80003dc6 <namex+0x6a>
    iput(ip);
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	adc080e7          	jalr	-1316(ra) # 80003982 <iput>
    return 0;
    80003eae:	4981                	li	s3,0
    80003eb0:	bf19                	j	80003dc6 <namex+0x6a>
  if(*path == 0)
    80003eb2:	d7fd                	beqz	a5,80003ea0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	85a6                	mv	a1,s1
    80003eba:	b7d1                	j	80003e7e <namex+0x122>

0000000080003ebc <dirlink>:
{
    80003ebc:	7139                	addi	sp,sp,-64
    80003ebe:	fc06                	sd	ra,56(sp)
    80003ec0:	f822                	sd	s0,48(sp)
    80003ec2:	f426                	sd	s1,40(sp)
    80003ec4:	f04a                	sd	s2,32(sp)
    80003ec6:	ec4e                	sd	s3,24(sp)
    80003ec8:	e852                	sd	s4,16(sp)
    80003eca:	0080                	addi	s0,sp,64
    80003ecc:	892a                	mv	s2,a0
    80003ece:	8a2e                	mv	s4,a1
    80003ed0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ed2:	4601                	li	a2,0
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	dd8080e7          	jalr	-552(ra) # 80003cac <dirlookup>
    80003edc:	e93d                	bnez	a0,80003f52 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ede:	04c92483          	lw	s1,76(s2)
    80003ee2:	c49d                	beqz	s1,80003f10 <dirlink+0x54>
    80003ee4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	4741                	li	a4,16
    80003ee8:	86a6                	mv	a3,s1
    80003eea:	fc040613          	addi	a2,s0,-64
    80003eee:	4581                	li	a1,0
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	b8a080e7          	jalr	-1142(ra) # 80003a7c <readi>
    80003efa:	47c1                	li	a5,16
    80003efc:	06f51163          	bne	a0,a5,80003f5e <dirlink+0xa2>
    if(de.inum == 0)
    80003f00:	fc045783          	lhu	a5,-64(s0)
    80003f04:	c791                	beqz	a5,80003f10 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f06:	24c1                	addiw	s1,s1,16
    80003f08:	04c92783          	lw	a5,76(s2)
    80003f0c:	fcf4ede3          	bltu	s1,a5,80003ee6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f10:	4639                	li	a2,14
    80003f12:	85d2                	mv	a1,s4
    80003f14:	fc240513          	addi	a0,s0,-62
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	ed2080e7          	jalr	-302(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003f20:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f24:	4741                	li	a4,16
    80003f26:	86a6                	mv	a3,s1
    80003f28:	fc040613          	addi	a2,s0,-64
    80003f2c:	4581                	li	a1,0
    80003f2e:	854a                	mv	a0,s2
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	c44080e7          	jalr	-956(ra) # 80003b74 <writei>
    80003f38:	872a                	mv	a4,a0
    80003f3a:	47c1                	li	a5,16
  return 0;
    80003f3c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f3e:	02f71863          	bne	a4,a5,80003f6e <dirlink+0xb2>
}
    80003f42:	70e2                	ld	ra,56(sp)
    80003f44:	7442                	ld	s0,48(sp)
    80003f46:	74a2                	ld	s1,40(sp)
    80003f48:	7902                	ld	s2,32(sp)
    80003f4a:	69e2                	ld	s3,24(sp)
    80003f4c:	6a42                	ld	s4,16(sp)
    80003f4e:	6121                	addi	sp,sp,64
    80003f50:	8082                	ret
    iput(ip);
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	a30080e7          	jalr	-1488(ra) # 80003982 <iput>
    return -1;
    80003f5a:	557d                	li	a0,-1
    80003f5c:	b7dd                	j	80003f42 <dirlink+0x86>
      panic("dirlink read");
    80003f5e:	00004517          	auipc	a0,0x4
    80003f62:	6a250513          	addi	a0,a0,1698 # 80008600 <syscalls+0x1d0>
    80003f66:	ffffc097          	auipc	ra,0xffffc
    80003f6a:	5ca080e7          	jalr	1482(ra) # 80000530 <panic>
    panic("dirlink");
    80003f6e:	00004517          	auipc	a0,0x4
    80003f72:	7a250513          	addi	a0,a0,1954 # 80008710 <syscalls+0x2e0>
    80003f76:	ffffc097          	auipc	ra,0xffffc
    80003f7a:	5ba080e7          	jalr	1466(ra) # 80000530 <panic>

0000000080003f7e <namei>:

struct inode*
namei(char *path)
{
    80003f7e:	1101                	addi	sp,sp,-32
    80003f80:	ec06                	sd	ra,24(sp)
    80003f82:	e822                	sd	s0,16(sp)
    80003f84:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f86:	fe040613          	addi	a2,s0,-32
    80003f8a:	4581                	li	a1,0
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	dd0080e7          	jalr	-560(ra) # 80003d5c <namex>
}
    80003f94:	60e2                	ld	ra,24(sp)
    80003f96:	6442                	ld	s0,16(sp)
    80003f98:	6105                	addi	sp,sp,32
    80003f9a:	8082                	ret

0000000080003f9c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f9c:	1141                	addi	sp,sp,-16
    80003f9e:	e406                	sd	ra,8(sp)
    80003fa0:	e022                	sd	s0,0(sp)
    80003fa2:	0800                	addi	s0,sp,16
    80003fa4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fa6:	4585                	li	a1,1
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	db4080e7          	jalr	-588(ra) # 80003d5c <namex>
}
    80003fb0:	60a2                	ld	ra,8(sp)
    80003fb2:	6402                	ld	s0,0(sp)
    80003fb4:	0141                	addi	sp,sp,16
    80003fb6:	8082                	ret

0000000080003fb8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fb8:	1101                	addi	sp,sp,-32
    80003fba:	ec06                	sd	ra,24(sp)
    80003fbc:	e822                	sd	s0,16(sp)
    80003fbe:	e426                	sd	s1,8(sp)
    80003fc0:	e04a                	sd	s2,0(sp)
    80003fc2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fc4:	0001d917          	auipc	s2,0x1d
    80003fc8:	4ac90913          	addi	s2,s2,1196 # 80021470 <log>
    80003fcc:	01892583          	lw	a1,24(s2)
    80003fd0:	02892503          	lw	a0,40(s2)
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	ff2080e7          	jalr	-14(ra) # 80002fc6 <bread>
    80003fdc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fde:	02c92683          	lw	a3,44(s2)
    80003fe2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fe4:	02d05763          	blez	a3,80004012 <write_head+0x5a>
    80003fe8:	0001d797          	auipc	a5,0x1d
    80003fec:	4b878793          	addi	a5,a5,1208 # 800214a0 <log+0x30>
    80003ff0:	05c50713          	addi	a4,a0,92
    80003ff4:	36fd                	addiw	a3,a3,-1
    80003ff6:	1682                	slli	a3,a3,0x20
    80003ff8:	9281                	srli	a3,a3,0x20
    80003ffa:	068a                	slli	a3,a3,0x2
    80003ffc:	0001d617          	auipc	a2,0x1d
    80004000:	4a860613          	addi	a2,a2,1192 # 800214a4 <log+0x34>
    80004004:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004006:	4390                	lw	a2,0(a5)
    80004008:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000400a:	0791                	addi	a5,a5,4
    8000400c:	0711                	addi	a4,a4,4
    8000400e:	fed79ce3          	bne	a5,a3,80004006 <write_head+0x4e>
  }
  bwrite(buf);
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	0a4080e7          	jalr	164(ra) # 800030b8 <bwrite>
  brelse(buf);
    8000401c:	8526                	mv	a0,s1
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	0d8080e7          	jalr	216(ra) # 800030f6 <brelse>
}
    80004026:	60e2                	ld	ra,24(sp)
    80004028:	6442                	ld	s0,16(sp)
    8000402a:	64a2                	ld	s1,8(sp)
    8000402c:	6902                	ld	s2,0(sp)
    8000402e:	6105                	addi	sp,sp,32
    80004030:	8082                	ret

0000000080004032 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004032:	0001d797          	auipc	a5,0x1d
    80004036:	46a7a783          	lw	a5,1130(a5) # 8002149c <log+0x2c>
    8000403a:	0af05d63          	blez	a5,800040f4 <install_trans+0xc2>
{
    8000403e:	7139                	addi	sp,sp,-64
    80004040:	fc06                	sd	ra,56(sp)
    80004042:	f822                	sd	s0,48(sp)
    80004044:	f426                	sd	s1,40(sp)
    80004046:	f04a                	sd	s2,32(sp)
    80004048:	ec4e                	sd	s3,24(sp)
    8000404a:	e852                	sd	s4,16(sp)
    8000404c:	e456                	sd	s5,8(sp)
    8000404e:	e05a                	sd	s6,0(sp)
    80004050:	0080                	addi	s0,sp,64
    80004052:	8b2a                	mv	s6,a0
    80004054:	0001da97          	auipc	s5,0x1d
    80004058:	44ca8a93          	addi	s5,s5,1100 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000405e:	0001d997          	auipc	s3,0x1d
    80004062:	41298993          	addi	s3,s3,1042 # 80021470 <log>
    80004066:	a035                	j	80004092 <install_trans+0x60>
      bunpin(dbuf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	166080e7          	jalr	358(ra) # 800031d0 <bunpin>
    brelse(lbuf);
    80004072:	854a                	mv	a0,s2
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	082080e7          	jalr	130(ra) # 800030f6 <brelse>
    brelse(dbuf);
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	078080e7          	jalr	120(ra) # 800030f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004086:	2a05                	addiw	s4,s4,1
    80004088:	0a91                	addi	s5,s5,4
    8000408a:	02c9a783          	lw	a5,44(s3)
    8000408e:	04fa5963          	bge	s4,a5,800040e0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004092:	0189a583          	lw	a1,24(s3)
    80004096:	014585bb          	addw	a1,a1,s4
    8000409a:	2585                	addiw	a1,a1,1
    8000409c:	0289a503          	lw	a0,40(s3)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	f26080e7          	jalr	-218(ra) # 80002fc6 <bread>
    800040a8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040aa:	000aa583          	lw	a1,0(s5)
    800040ae:	0289a503          	lw	a0,40(s3)
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	f14080e7          	jalr	-236(ra) # 80002fc6 <bread>
    800040ba:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040bc:	40000613          	li	a2,1024
    800040c0:	05890593          	addi	a1,s2,88
    800040c4:	05850513          	addi	a0,a0,88
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	c6a080e7          	jalr	-918(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040d0:	8526                	mv	a0,s1
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	fe6080e7          	jalr	-26(ra) # 800030b8 <bwrite>
    if(recovering == 0)
    800040da:	f80b1ce3          	bnez	s6,80004072 <install_trans+0x40>
    800040de:	b769                	j	80004068 <install_trans+0x36>
}
    800040e0:	70e2                	ld	ra,56(sp)
    800040e2:	7442                	ld	s0,48(sp)
    800040e4:	74a2                	ld	s1,40(sp)
    800040e6:	7902                	ld	s2,32(sp)
    800040e8:	69e2                	ld	s3,24(sp)
    800040ea:	6a42                	ld	s4,16(sp)
    800040ec:	6aa2                	ld	s5,8(sp)
    800040ee:	6b02                	ld	s6,0(sp)
    800040f0:	6121                	addi	sp,sp,64
    800040f2:	8082                	ret
    800040f4:	8082                	ret

00000000800040f6 <initlog>:
{
    800040f6:	7179                	addi	sp,sp,-48
    800040f8:	f406                	sd	ra,40(sp)
    800040fa:	f022                	sd	s0,32(sp)
    800040fc:	ec26                	sd	s1,24(sp)
    800040fe:	e84a                	sd	s2,16(sp)
    80004100:	e44e                	sd	s3,8(sp)
    80004102:	1800                	addi	s0,sp,48
    80004104:	892a                	mv	s2,a0
    80004106:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004108:	0001d497          	auipc	s1,0x1d
    8000410c:	36848493          	addi	s1,s1,872 # 80021470 <log>
    80004110:	00004597          	auipc	a1,0x4
    80004114:	50058593          	addi	a1,a1,1280 # 80008610 <syscalls+0x1e0>
    80004118:	8526                	mv	a0,s1
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	a2c080e7          	jalr	-1492(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004122:	0149a583          	lw	a1,20(s3)
    80004126:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004128:	0109a783          	lw	a5,16(s3)
    8000412c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000412e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004132:	854a                	mv	a0,s2
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	e92080e7          	jalr	-366(ra) # 80002fc6 <bread>
  log.lh.n = lh->n;
    8000413c:	4d3c                	lw	a5,88(a0)
    8000413e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004140:	02f05563          	blez	a5,8000416a <initlog+0x74>
    80004144:	05c50713          	addi	a4,a0,92
    80004148:	0001d697          	auipc	a3,0x1d
    8000414c:	35868693          	addi	a3,a3,856 # 800214a0 <log+0x30>
    80004150:	37fd                	addiw	a5,a5,-1
    80004152:	1782                	slli	a5,a5,0x20
    80004154:	9381                	srli	a5,a5,0x20
    80004156:	078a                	slli	a5,a5,0x2
    80004158:	06050613          	addi	a2,a0,96
    8000415c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000415e:	4310                	lw	a2,0(a4)
    80004160:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004162:	0711                	addi	a4,a4,4
    80004164:	0691                	addi	a3,a3,4
    80004166:	fef71ce3          	bne	a4,a5,8000415e <initlog+0x68>
  brelse(buf);
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	f8c080e7          	jalr	-116(ra) # 800030f6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004172:	4505                	li	a0,1
    80004174:	00000097          	auipc	ra,0x0
    80004178:	ebe080e7          	jalr	-322(ra) # 80004032 <install_trans>
  log.lh.n = 0;
    8000417c:	0001d797          	auipc	a5,0x1d
    80004180:	3207a023          	sw	zero,800(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004184:	00000097          	auipc	ra,0x0
    80004188:	e34080e7          	jalr	-460(ra) # 80003fb8 <write_head>
}
    8000418c:	70a2                	ld	ra,40(sp)
    8000418e:	7402                	ld	s0,32(sp)
    80004190:	64e2                	ld	s1,24(sp)
    80004192:	6942                	ld	s2,16(sp)
    80004194:	69a2                	ld	s3,8(sp)
    80004196:	6145                	addi	sp,sp,48
    80004198:	8082                	ret

000000008000419a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000419a:	1101                	addi	sp,sp,-32
    8000419c:	ec06                	sd	ra,24(sp)
    8000419e:	e822                	sd	s0,16(sp)
    800041a0:	e426                	sd	s1,8(sp)
    800041a2:	e04a                	sd	s2,0(sp)
    800041a4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041a6:	0001d517          	auipc	a0,0x1d
    800041aa:	2ca50513          	addi	a0,a0,714 # 80021470 <log>
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	a28080e7          	jalr	-1496(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041b6:	0001d497          	auipc	s1,0x1d
    800041ba:	2ba48493          	addi	s1,s1,698 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041be:	4979                	li	s2,30
    800041c0:	a039                	j	800041ce <begin_op+0x34>
      sleep(&log, &log.lock);
    800041c2:	85a6                	mv	a1,s1
    800041c4:	8526                	mv	a0,s1
    800041c6:	ffffe097          	auipc	ra,0xffffe
    800041ca:	ef6080e7          	jalr	-266(ra) # 800020bc <sleep>
    if(log.committing){
    800041ce:	50dc                	lw	a5,36(s1)
    800041d0:	fbed                	bnez	a5,800041c2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041d2:	509c                	lw	a5,32(s1)
    800041d4:	0017871b          	addiw	a4,a5,1
    800041d8:	0007069b          	sext.w	a3,a4
    800041dc:	0027179b          	slliw	a5,a4,0x2
    800041e0:	9fb9                	addw	a5,a5,a4
    800041e2:	0017979b          	slliw	a5,a5,0x1
    800041e6:	54d8                	lw	a4,44(s1)
    800041e8:	9fb9                	addw	a5,a5,a4
    800041ea:	00f95963          	bge	s2,a5,800041fc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041ee:	85a6                	mv	a1,s1
    800041f0:	8526                	mv	a0,s1
    800041f2:	ffffe097          	auipc	ra,0xffffe
    800041f6:	eca080e7          	jalr	-310(ra) # 800020bc <sleep>
    800041fa:	bfd1                	j	800041ce <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041fc:	0001d517          	auipc	a0,0x1d
    80004200:	27450513          	addi	a0,a0,628 # 80021470 <log>
    80004204:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	a84080e7          	jalr	-1404(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000420e:	60e2                	ld	ra,24(sp)
    80004210:	6442                	ld	s0,16(sp)
    80004212:	64a2                	ld	s1,8(sp)
    80004214:	6902                	ld	s2,0(sp)
    80004216:	6105                	addi	sp,sp,32
    80004218:	8082                	ret

000000008000421a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000421a:	7139                	addi	sp,sp,-64
    8000421c:	fc06                	sd	ra,56(sp)
    8000421e:	f822                	sd	s0,48(sp)
    80004220:	f426                	sd	s1,40(sp)
    80004222:	f04a                	sd	s2,32(sp)
    80004224:	ec4e                	sd	s3,24(sp)
    80004226:	e852                	sd	s4,16(sp)
    80004228:	e456                	sd	s5,8(sp)
    8000422a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000422c:	0001d497          	auipc	s1,0x1d
    80004230:	24448493          	addi	s1,s1,580 # 80021470 <log>
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	9a0080e7          	jalr	-1632(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000423e:	509c                	lw	a5,32(s1)
    80004240:	37fd                	addiw	a5,a5,-1
    80004242:	0007891b          	sext.w	s2,a5
    80004246:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004248:	50dc                	lw	a5,36(s1)
    8000424a:	efb9                	bnez	a5,800042a8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000424c:	06091663          	bnez	s2,800042b8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004250:	0001d497          	auipc	s1,0x1d
    80004254:	22048493          	addi	s1,s1,544 # 80021470 <log>
    80004258:	4785                	li	a5,1
    8000425a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000425c:	8526                	mv	a0,s1
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004266:	54dc                	lw	a5,44(s1)
    80004268:	06f04763          	bgtz	a5,800042d6 <end_op+0xbc>
    acquire(&log.lock);
    8000426c:	0001d497          	auipc	s1,0x1d
    80004270:	20448493          	addi	s1,s1,516 # 80021470 <log>
    80004274:	8526                	mv	a0,s1
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	960080e7          	jalr	-1696(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000427e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004282:	8526                	mv	a0,s1
    80004284:	ffffe097          	auipc	ra,0xffffe
    80004288:	fc4080e7          	jalr	-60(ra) # 80002248 <wakeup>
    release(&log.lock);
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	9fc080e7          	jalr	-1540(ra) # 80000c8a <release>
}
    80004296:	70e2                	ld	ra,56(sp)
    80004298:	7442                	ld	s0,48(sp)
    8000429a:	74a2                	ld	s1,40(sp)
    8000429c:	7902                	ld	s2,32(sp)
    8000429e:	69e2                	ld	s3,24(sp)
    800042a0:	6a42                	ld	s4,16(sp)
    800042a2:	6aa2                	ld	s5,8(sp)
    800042a4:	6121                	addi	sp,sp,64
    800042a6:	8082                	ret
    panic("log.committing");
    800042a8:	00004517          	auipc	a0,0x4
    800042ac:	37050513          	addi	a0,a0,880 # 80008618 <syscalls+0x1e8>
    800042b0:	ffffc097          	auipc	ra,0xffffc
    800042b4:	280080e7          	jalr	640(ra) # 80000530 <panic>
    wakeup(&log);
    800042b8:	0001d497          	auipc	s1,0x1d
    800042bc:	1b848493          	addi	s1,s1,440 # 80021470 <log>
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffe097          	auipc	ra,0xffffe
    800042c6:	f86080e7          	jalr	-122(ra) # 80002248 <wakeup>
  release(&log.lock);
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	9be080e7          	jalr	-1602(ra) # 80000c8a <release>
  if(do_commit){
    800042d4:	b7c9                	j	80004296 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d6:	0001da97          	auipc	s5,0x1d
    800042da:	1caa8a93          	addi	s5,s5,458 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042de:	0001da17          	auipc	s4,0x1d
    800042e2:	192a0a13          	addi	s4,s4,402 # 80021470 <log>
    800042e6:	018a2583          	lw	a1,24(s4)
    800042ea:	012585bb          	addw	a1,a1,s2
    800042ee:	2585                	addiw	a1,a1,1
    800042f0:	028a2503          	lw	a0,40(s4)
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	cd2080e7          	jalr	-814(ra) # 80002fc6 <bread>
    800042fc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042fe:	000aa583          	lw	a1,0(s5)
    80004302:	028a2503          	lw	a0,40(s4)
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	cc0080e7          	jalr	-832(ra) # 80002fc6 <bread>
    8000430e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004310:	40000613          	li	a2,1024
    80004314:	05850593          	addi	a1,a0,88
    80004318:	05848513          	addi	a0,s1,88
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	a16080e7          	jalr	-1514(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	d92080e7          	jalr	-622(ra) # 800030b8 <bwrite>
    brelse(from);
    8000432e:	854e                	mv	a0,s3
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	dc6080e7          	jalr	-570(ra) # 800030f6 <brelse>
    brelse(to);
    80004338:	8526                	mv	a0,s1
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	dbc080e7          	jalr	-580(ra) # 800030f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004342:	2905                	addiw	s2,s2,1
    80004344:	0a91                	addi	s5,s5,4
    80004346:	02ca2783          	lw	a5,44(s4)
    8000434a:	f8f94ee3          	blt	s2,a5,800042e6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	c6a080e7          	jalr	-918(ra) # 80003fb8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004356:	4501                	li	a0,0
    80004358:	00000097          	auipc	ra,0x0
    8000435c:	cda080e7          	jalr	-806(ra) # 80004032 <install_trans>
    log.lh.n = 0;
    80004360:	0001d797          	auipc	a5,0x1d
    80004364:	1207ae23          	sw	zero,316(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	c50080e7          	jalr	-944(ra) # 80003fb8 <write_head>
    80004370:	bdf5                	j	8000426c <end_op+0x52>

0000000080004372 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
    8000437e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004380:	0001d917          	auipc	s2,0x1d
    80004384:	0f090913          	addi	s2,s2,240 # 80021470 <log>
    80004388:	854a                	mv	a0,s2
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	84c080e7          	jalr	-1972(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004392:	02c92603          	lw	a2,44(s2)
    80004396:	47f5                	li	a5,29
    80004398:	06c7c563          	blt	a5,a2,80004402 <log_write+0x90>
    8000439c:	0001d797          	auipc	a5,0x1d
    800043a0:	0f07a783          	lw	a5,240(a5) # 8002148c <log+0x1c>
    800043a4:	37fd                	addiw	a5,a5,-1
    800043a6:	04f65e63          	bge	a2,a5,80004402 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043aa:	0001d797          	auipc	a5,0x1d
    800043ae:	0e67a783          	lw	a5,230(a5) # 80021490 <log+0x20>
    800043b2:	06f05063          	blez	a5,80004412 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043b6:	4781                	li	a5,0
    800043b8:	06c05563          	blez	a2,80004422 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043bc:	44cc                	lw	a1,12(s1)
    800043be:	0001d717          	auipc	a4,0x1d
    800043c2:	0e270713          	addi	a4,a4,226 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043c8:	4314                	lw	a3,0(a4)
    800043ca:	04b68c63          	beq	a3,a1,80004422 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043ce:	2785                	addiw	a5,a5,1
    800043d0:	0711                	addi	a4,a4,4
    800043d2:	fef61be3          	bne	a2,a5,800043c8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043d6:	0621                	addi	a2,a2,8
    800043d8:	060a                	slli	a2,a2,0x2
    800043da:	0001d797          	auipc	a5,0x1d
    800043de:	09678793          	addi	a5,a5,150 # 80021470 <log>
    800043e2:	963e                	add	a2,a2,a5
    800043e4:	44dc                	lw	a5,12(s1)
    800043e6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	daa080e7          	jalr	-598(ra) # 80003194 <bpin>
    log.lh.n++;
    800043f2:	0001d717          	auipc	a4,0x1d
    800043f6:	07e70713          	addi	a4,a4,126 # 80021470 <log>
    800043fa:	575c                	lw	a5,44(a4)
    800043fc:	2785                	addiw	a5,a5,1
    800043fe:	d75c                	sw	a5,44(a4)
    80004400:	a835                	j	8000443c <log_write+0xca>
    panic("too big a transaction");
    80004402:	00004517          	auipc	a0,0x4
    80004406:	22650513          	addi	a0,a0,550 # 80008628 <syscalls+0x1f8>
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	126080e7          	jalr	294(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    80004412:	00004517          	auipc	a0,0x4
    80004416:	22e50513          	addi	a0,a0,558 # 80008640 <syscalls+0x210>
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	116080e7          	jalr	278(ra) # 80000530 <panic>
  log.lh.block[i] = b->blockno;
    80004422:	00878713          	addi	a4,a5,8
    80004426:	00271693          	slli	a3,a4,0x2
    8000442a:	0001d717          	auipc	a4,0x1d
    8000442e:	04670713          	addi	a4,a4,70 # 80021470 <log>
    80004432:	9736                	add	a4,a4,a3
    80004434:	44d4                	lw	a3,12(s1)
    80004436:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004438:	faf608e3          	beq	a2,a5,800043e8 <log_write+0x76>
  }
  release(&log.lock);
    8000443c:	0001d517          	auipc	a0,0x1d
    80004440:	03450513          	addi	a0,a0,52 # 80021470 <log>
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
}
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6902                	ld	s2,0(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004458:	1101                	addi	sp,sp,-32
    8000445a:	ec06                	sd	ra,24(sp)
    8000445c:	e822                	sd	s0,16(sp)
    8000445e:	e426                	sd	s1,8(sp)
    80004460:	e04a                	sd	s2,0(sp)
    80004462:	1000                	addi	s0,sp,32
    80004464:	84aa                	mv	s1,a0
    80004466:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004468:	00004597          	auipc	a1,0x4
    8000446c:	1f858593          	addi	a1,a1,504 # 80008660 <syscalls+0x230>
    80004470:	0521                	addi	a0,a0,8
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	6d4080e7          	jalr	1748(ra) # 80000b46 <initlock>
  lk->name = name;
    8000447a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000447e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004482:	0204a423          	sw	zero,40(s1)
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6902                	ld	s2,0(sp)
    8000448e:	6105                	addi	sp,sp,32
    80004490:	8082                	ret

0000000080004492 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004492:	1101                	addi	sp,sp,-32
    80004494:	ec06                	sd	ra,24(sp)
    80004496:	e822                	sd	s0,16(sp)
    80004498:	e426                	sd	s1,8(sp)
    8000449a:	e04a                	sd	s2,0(sp)
    8000449c:	1000                	addi	s0,sp,32
    8000449e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044a0:	00850913          	addi	s2,a0,8
    800044a4:	854a                	mv	a0,s2
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	730080e7          	jalr	1840(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044ae:	409c                	lw	a5,0(s1)
    800044b0:	cb89                	beqz	a5,800044c2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044b2:	85ca                	mv	a1,s2
    800044b4:	8526                	mv	a0,s1
    800044b6:	ffffe097          	auipc	ra,0xffffe
    800044ba:	c06080e7          	jalr	-1018(ra) # 800020bc <sleep>
  while (lk->locked) {
    800044be:	409c                	lw	a5,0(s1)
    800044c0:	fbed                	bnez	a5,800044b2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044c2:	4785                	li	a5,1
    800044c4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	4ce080e7          	jalr	1230(ra) # 80001994 <myproc>
    800044ce:	591c                	lw	a5,48(a0)
    800044d0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044d2:	854a                	mv	a0,s2
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	7b6080e7          	jalr	1974(ra) # 80000c8a <release>
}
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	64a2                	ld	s1,8(sp)
    800044e2:	6902                	ld	s2,0(sp)
    800044e4:	6105                	addi	sp,sp,32
    800044e6:	8082                	ret

00000000800044e8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044e8:	1101                	addi	sp,sp,-32
    800044ea:	ec06                	sd	ra,24(sp)
    800044ec:	e822                	sd	s0,16(sp)
    800044ee:	e426                	sd	s1,8(sp)
    800044f0:	e04a                	sd	s2,0(sp)
    800044f2:	1000                	addi	s0,sp,32
    800044f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044f6:	00850913          	addi	s2,a0,8
    800044fa:	854a                	mv	a0,s2
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	6da080e7          	jalr	1754(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004504:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004508:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000450c:	8526                	mv	a0,s1
    8000450e:	ffffe097          	auipc	ra,0xffffe
    80004512:	d3a080e7          	jalr	-710(ra) # 80002248 <wakeup>
  release(&lk->lk);
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	772080e7          	jalr	1906(ra) # 80000c8a <release>
}
    80004520:	60e2                	ld	ra,24(sp)
    80004522:	6442                	ld	s0,16(sp)
    80004524:	64a2                	ld	s1,8(sp)
    80004526:	6902                	ld	s2,0(sp)
    80004528:	6105                	addi	sp,sp,32
    8000452a:	8082                	ret

000000008000452c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000452c:	7179                	addi	sp,sp,-48
    8000452e:	f406                	sd	ra,40(sp)
    80004530:	f022                	sd	s0,32(sp)
    80004532:	ec26                	sd	s1,24(sp)
    80004534:	e84a                	sd	s2,16(sp)
    80004536:	e44e                	sd	s3,8(sp)
    80004538:	1800                	addi	s0,sp,48
    8000453a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000453c:	00850913          	addi	s2,a0,8
    80004540:	854a                	mv	a0,s2
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	694080e7          	jalr	1684(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454a:	409c                	lw	a5,0(s1)
    8000454c:	ef99                	bnez	a5,8000456a <holdingsleep+0x3e>
    8000454e:	4481                	li	s1,0
  release(&lk->lk);
    80004550:	854a                	mv	a0,s2
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	738080e7          	jalr	1848(ra) # 80000c8a <release>
  return r;
}
    8000455a:	8526                	mv	a0,s1
    8000455c:	70a2                	ld	ra,40(sp)
    8000455e:	7402                	ld	s0,32(sp)
    80004560:	64e2                	ld	s1,24(sp)
    80004562:	6942                	ld	s2,16(sp)
    80004564:	69a2                	ld	s3,8(sp)
    80004566:	6145                	addi	sp,sp,48
    80004568:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000456a:	0284a983          	lw	s3,40(s1)
    8000456e:	ffffd097          	auipc	ra,0xffffd
    80004572:	426080e7          	jalr	1062(ra) # 80001994 <myproc>
    80004576:	5904                	lw	s1,48(a0)
    80004578:	413484b3          	sub	s1,s1,s3
    8000457c:	0014b493          	seqz	s1,s1
    80004580:	bfc1                	j	80004550 <holdingsleep+0x24>

0000000080004582 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004582:	1141                	addi	sp,sp,-16
    80004584:	e406                	sd	ra,8(sp)
    80004586:	e022                	sd	s0,0(sp)
    80004588:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000458a:	00004597          	auipc	a1,0x4
    8000458e:	0e658593          	addi	a1,a1,230 # 80008670 <syscalls+0x240>
    80004592:	0001d517          	auipc	a0,0x1d
    80004596:	02650513          	addi	a0,a0,38 # 800215b8 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	5ac080e7          	jalr	1452(ra) # 80000b46 <initlock>
}
    800045a2:	60a2                	ld	ra,8(sp)
    800045a4:	6402                	ld	s0,0(sp)
    800045a6:	0141                	addi	sp,sp,16
    800045a8:	8082                	ret

00000000800045aa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045aa:	1101                	addi	sp,sp,-32
    800045ac:	ec06                	sd	ra,24(sp)
    800045ae:	e822                	sd	s0,16(sp)
    800045b0:	e426                	sd	s1,8(sp)
    800045b2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	00450513          	addi	a0,a0,4 # 800215b8 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	61a080e7          	jalr	1562(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c4:	0001d497          	auipc	s1,0x1d
    800045c8:	00c48493          	addi	s1,s1,12 # 800215d0 <ftable+0x18>
    800045cc:	0001e717          	auipc	a4,0x1e
    800045d0:	fa470713          	addi	a4,a4,-92 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800045d4:	40dc                	lw	a5,4(s1)
    800045d6:	cf99                	beqz	a5,800045f4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d8:	02848493          	addi	s1,s1,40
    800045dc:	fee49ce3          	bne	s1,a4,800045d4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	fd850513          	addi	a0,a0,-40 # 800215b8 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	6a2080e7          	jalr	1698(ra) # 80000c8a <release>
  return 0;
    800045f0:	4481                	li	s1,0
    800045f2:	a819                	j	80004608 <filealloc+0x5e>
      f->ref = 1;
    800045f4:	4785                	li	a5,1
    800045f6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045f8:	0001d517          	auipc	a0,0x1d
    800045fc:	fc050513          	addi	a0,a0,-64 # 800215b8 <ftable>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	68a080e7          	jalr	1674(ra) # 80000c8a <release>
}
    80004608:	8526                	mv	a0,s1
    8000460a:	60e2                	ld	ra,24(sp)
    8000460c:	6442                	ld	s0,16(sp)
    8000460e:	64a2                	ld	s1,8(sp)
    80004610:	6105                	addi	sp,sp,32
    80004612:	8082                	ret

0000000080004614 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004614:	1101                	addi	sp,sp,-32
    80004616:	ec06                	sd	ra,24(sp)
    80004618:	e822                	sd	s0,16(sp)
    8000461a:	e426                	sd	s1,8(sp)
    8000461c:	1000                	addi	s0,sp,32
    8000461e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004620:	0001d517          	auipc	a0,0x1d
    80004624:	f9850513          	addi	a0,a0,-104 # 800215b8 <ftable>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	5ae080e7          	jalr	1454(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004630:	40dc                	lw	a5,4(s1)
    80004632:	02f05263          	blez	a5,80004656 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004636:	2785                	addiw	a5,a5,1
    80004638:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000463a:	0001d517          	auipc	a0,0x1d
    8000463e:	f7e50513          	addi	a0,a0,-130 # 800215b8 <ftable>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	648080e7          	jalr	1608(ra) # 80000c8a <release>
  return f;
}
    8000464a:	8526                	mv	a0,s1
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6105                	addi	sp,sp,32
    80004654:	8082                	ret
    panic("filedup");
    80004656:	00004517          	auipc	a0,0x4
    8000465a:	02250513          	addi	a0,a0,34 # 80008678 <syscalls+0x248>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	ed2080e7          	jalr	-302(ra) # 80000530 <panic>

0000000080004666 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004666:	7139                	addi	sp,sp,-64
    80004668:	fc06                	sd	ra,56(sp)
    8000466a:	f822                	sd	s0,48(sp)
    8000466c:	f426                	sd	s1,40(sp)
    8000466e:	f04a                	sd	s2,32(sp)
    80004670:	ec4e                	sd	s3,24(sp)
    80004672:	e852                	sd	s4,16(sp)
    80004674:	e456                	sd	s5,8(sp)
    80004676:	0080                	addi	s0,sp,64
    80004678:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000467a:	0001d517          	auipc	a0,0x1d
    8000467e:	f3e50513          	addi	a0,a0,-194 # 800215b8 <ftable>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	554080e7          	jalr	1364(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000468a:	40dc                	lw	a5,4(s1)
    8000468c:	06f05163          	blez	a5,800046ee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004690:	37fd                	addiw	a5,a5,-1
    80004692:	0007871b          	sext.w	a4,a5
    80004696:	c0dc                	sw	a5,4(s1)
    80004698:	06e04363          	bgtz	a4,800046fe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000469c:	0004a903          	lw	s2,0(s1)
    800046a0:	0094ca83          	lbu	s5,9(s1)
    800046a4:	0104ba03          	ld	s4,16(s1)
    800046a8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046b0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046b4:	0001d517          	auipc	a0,0x1d
    800046b8:	f0450513          	addi	a0,a0,-252 # 800215b8 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	5ce080e7          	jalr	1486(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046c4:	4785                	li	a5,1
    800046c6:	04f90d63          	beq	s2,a5,80004720 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ca:	3979                	addiw	s2,s2,-2
    800046cc:	4785                	li	a5,1
    800046ce:	0527e063          	bltu	a5,s2,8000470e <fileclose+0xa8>
    begin_op();
    800046d2:	00000097          	auipc	ra,0x0
    800046d6:	ac8080e7          	jalr	-1336(ra) # 8000419a <begin_op>
    iput(ff.ip);
    800046da:	854e                	mv	a0,s3
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	2a6080e7          	jalr	678(ra) # 80003982 <iput>
    end_op();
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	b36080e7          	jalr	-1226(ra) # 8000421a <end_op>
    800046ec:	a00d                	j	8000470e <fileclose+0xa8>
    panic("fileclose");
    800046ee:	00004517          	auipc	a0,0x4
    800046f2:	f9250513          	addi	a0,a0,-110 # 80008680 <syscalls+0x250>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	e3a080e7          	jalr	-454(ra) # 80000530 <panic>
    release(&ftable.lock);
    800046fe:	0001d517          	auipc	a0,0x1d
    80004702:	eba50513          	addi	a0,a0,-326 # 800215b8 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	584080e7          	jalr	1412(ra) # 80000c8a <release>
  }
}
    8000470e:	70e2                	ld	ra,56(sp)
    80004710:	7442                	ld	s0,48(sp)
    80004712:	74a2                	ld	s1,40(sp)
    80004714:	7902                	ld	s2,32(sp)
    80004716:	69e2                	ld	s3,24(sp)
    80004718:	6a42                	ld	s4,16(sp)
    8000471a:	6aa2                	ld	s5,8(sp)
    8000471c:	6121                	addi	sp,sp,64
    8000471e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004720:	85d6                	mv	a1,s5
    80004722:	8552                	mv	a0,s4
    80004724:	00000097          	auipc	ra,0x0
    80004728:	34c080e7          	jalr	844(ra) # 80004a70 <pipeclose>
    8000472c:	b7cd                	j	8000470e <fileclose+0xa8>

000000008000472e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000472e:	715d                	addi	sp,sp,-80
    80004730:	e486                	sd	ra,72(sp)
    80004732:	e0a2                	sd	s0,64(sp)
    80004734:	fc26                	sd	s1,56(sp)
    80004736:	f84a                	sd	s2,48(sp)
    80004738:	f44e                	sd	s3,40(sp)
    8000473a:	0880                	addi	s0,sp,80
    8000473c:	84aa                	mv	s1,a0
    8000473e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004740:	ffffd097          	auipc	ra,0xffffd
    80004744:	254080e7          	jalr	596(ra) # 80001994 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004748:	409c                	lw	a5,0(s1)
    8000474a:	37f9                	addiw	a5,a5,-2
    8000474c:	4705                	li	a4,1
    8000474e:	04f76763          	bltu	a4,a5,8000479c <filestat+0x6e>
    80004752:	892a                	mv	s2,a0
    ilock(f->ip);
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	072080e7          	jalr	114(ra) # 800037c8 <ilock>
    stati(f->ip, &st);
    8000475e:	fb840593          	addi	a1,s0,-72
    80004762:	6c88                	ld	a0,24(s1)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	2ee080e7          	jalr	750(ra) # 80003a52 <stati>
    iunlock(f->ip);
    8000476c:	6c88                	ld	a0,24(s1)
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	11c080e7          	jalr	284(ra) # 8000388a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004776:	46e1                	li	a3,24
    80004778:	fb840613          	addi	a2,s0,-72
    8000477c:	85ce                	mv	a1,s3
    8000477e:	05093503          	ld	a0,80(s2)
    80004782:	ffffd097          	auipc	ra,0xffffd
    80004786:	ed4080e7          	jalr	-300(ra) # 80001656 <copyout>
    8000478a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000478e:	60a6                	ld	ra,72(sp)
    80004790:	6406                	ld	s0,64(sp)
    80004792:	74e2                	ld	s1,56(sp)
    80004794:	7942                	ld	s2,48(sp)
    80004796:	79a2                	ld	s3,40(sp)
    80004798:	6161                	addi	sp,sp,80
    8000479a:	8082                	ret
  return -1;
    8000479c:	557d                	li	a0,-1
    8000479e:	bfc5                	j	8000478e <filestat+0x60>

00000000800047a0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047a0:	7179                	addi	sp,sp,-48
    800047a2:	f406                	sd	ra,40(sp)
    800047a4:	f022                	sd	s0,32(sp)
    800047a6:	ec26                	sd	s1,24(sp)
    800047a8:	e84a                	sd	s2,16(sp)
    800047aa:	e44e                	sd	s3,8(sp)
    800047ac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047ae:	00854783          	lbu	a5,8(a0)
    800047b2:	c3d5                	beqz	a5,80004856 <fileread+0xb6>
    800047b4:	84aa                	mv	s1,a0
    800047b6:	89ae                	mv	s3,a1
    800047b8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ba:	411c                	lw	a5,0(a0)
    800047bc:	4705                	li	a4,1
    800047be:	04e78963          	beq	a5,a4,80004810 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c2:	470d                	li	a4,3
    800047c4:	04e78d63          	beq	a5,a4,8000481e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c8:	4709                	li	a4,2
    800047ca:	06e79e63          	bne	a5,a4,80004846 <fileread+0xa6>
    ilock(f->ip);
    800047ce:	6d08                	ld	a0,24(a0)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	ff8080e7          	jalr	-8(ra) # 800037c8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047d8:	874a                	mv	a4,s2
    800047da:	5094                	lw	a3,32(s1)
    800047dc:	864e                	mv	a2,s3
    800047de:	4585                	li	a1,1
    800047e0:	6c88                	ld	a0,24(s1)
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	29a080e7          	jalr	666(ra) # 80003a7c <readi>
    800047ea:	892a                	mv	s2,a0
    800047ec:	00a05563          	blez	a0,800047f6 <fileread+0x56>
      f->off += r;
    800047f0:	509c                	lw	a5,32(s1)
    800047f2:	9fa9                	addw	a5,a5,a0
    800047f4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047f6:	6c88                	ld	a0,24(s1)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	092080e7          	jalr	146(ra) # 8000388a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004800:	854a                	mv	a0,s2
    80004802:	70a2                	ld	ra,40(sp)
    80004804:	7402                	ld	s0,32(sp)
    80004806:	64e2                	ld	s1,24(sp)
    80004808:	6942                	ld	s2,16(sp)
    8000480a:	69a2                	ld	s3,8(sp)
    8000480c:	6145                	addi	sp,sp,48
    8000480e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004810:	6908                	ld	a0,16(a0)
    80004812:	00000097          	auipc	ra,0x0
    80004816:	3c8080e7          	jalr	968(ra) # 80004bda <piperead>
    8000481a:	892a                	mv	s2,a0
    8000481c:	b7d5                	j	80004800 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000481e:	02451783          	lh	a5,36(a0)
    80004822:	03079693          	slli	a3,a5,0x30
    80004826:	92c1                	srli	a3,a3,0x30
    80004828:	4725                	li	a4,9
    8000482a:	02d76863          	bltu	a4,a3,8000485a <fileread+0xba>
    8000482e:	0792                	slli	a5,a5,0x4
    80004830:	0001d717          	auipc	a4,0x1d
    80004834:	ce870713          	addi	a4,a4,-792 # 80021518 <devsw>
    80004838:	97ba                	add	a5,a5,a4
    8000483a:	639c                	ld	a5,0(a5)
    8000483c:	c38d                	beqz	a5,8000485e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000483e:	4505                	li	a0,1
    80004840:	9782                	jalr	a5
    80004842:	892a                	mv	s2,a0
    80004844:	bf75                	j	80004800 <fileread+0x60>
    panic("fileread");
    80004846:	00004517          	auipc	a0,0x4
    8000484a:	e4a50513          	addi	a0,a0,-438 # 80008690 <syscalls+0x260>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	ce2080e7          	jalr	-798(ra) # 80000530 <panic>
    return -1;
    80004856:	597d                	li	s2,-1
    80004858:	b765                	j	80004800 <fileread+0x60>
      return -1;
    8000485a:	597d                	li	s2,-1
    8000485c:	b755                	j	80004800 <fileread+0x60>
    8000485e:	597d                	li	s2,-1
    80004860:	b745                	j	80004800 <fileread+0x60>

0000000080004862 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004862:	715d                	addi	sp,sp,-80
    80004864:	e486                	sd	ra,72(sp)
    80004866:	e0a2                	sd	s0,64(sp)
    80004868:	fc26                	sd	s1,56(sp)
    8000486a:	f84a                	sd	s2,48(sp)
    8000486c:	f44e                	sd	s3,40(sp)
    8000486e:	f052                	sd	s4,32(sp)
    80004870:	ec56                	sd	s5,24(sp)
    80004872:	e85a                	sd	s6,16(sp)
    80004874:	e45e                	sd	s7,8(sp)
    80004876:	e062                	sd	s8,0(sp)
    80004878:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000487a:	00954783          	lbu	a5,9(a0)
    8000487e:	10078663          	beqz	a5,8000498a <filewrite+0x128>
    80004882:	892a                	mv	s2,a0
    80004884:	8aae                	mv	s5,a1
    80004886:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004888:	411c                	lw	a5,0(a0)
    8000488a:	4705                	li	a4,1
    8000488c:	02e78263          	beq	a5,a4,800048b0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004890:	470d                	li	a4,3
    80004892:	02e78663          	beq	a5,a4,800048be <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004896:	4709                	li	a4,2
    80004898:	0ee79163          	bne	a5,a4,8000497a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000489c:	0ac05d63          	blez	a2,80004956 <filewrite+0xf4>
    int i = 0;
    800048a0:	4981                	li	s3,0
    800048a2:	6b05                	lui	s6,0x1
    800048a4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048a8:	6b85                	lui	s7,0x1
    800048aa:	c00b8b9b          	addiw	s7,s7,-1024
    800048ae:	a861                	j	80004946 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048b0:	6908                	ld	a0,16(a0)
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	22e080e7          	jalr	558(ra) # 80004ae0 <pipewrite>
    800048ba:	8a2a                	mv	s4,a0
    800048bc:	a045                	j	8000495c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048be:	02451783          	lh	a5,36(a0)
    800048c2:	03079693          	slli	a3,a5,0x30
    800048c6:	92c1                	srli	a3,a3,0x30
    800048c8:	4725                	li	a4,9
    800048ca:	0cd76263          	bltu	a4,a3,8000498e <filewrite+0x12c>
    800048ce:	0792                	slli	a5,a5,0x4
    800048d0:	0001d717          	auipc	a4,0x1d
    800048d4:	c4870713          	addi	a4,a4,-952 # 80021518 <devsw>
    800048d8:	97ba                	add	a5,a5,a4
    800048da:	679c                	ld	a5,8(a5)
    800048dc:	cbdd                	beqz	a5,80004992 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048de:	4505                	li	a0,1
    800048e0:	9782                	jalr	a5
    800048e2:	8a2a                	mv	s4,a0
    800048e4:	a8a5                	j	8000495c <filewrite+0xfa>
    800048e6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	8b0080e7          	jalr	-1872(ra) # 8000419a <begin_op>
      ilock(f->ip);
    800048f2:	01893503          	ld	a0,24(s2)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	ed2080e7          	jalr	-302(ra) # 800037c8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048fe:	8762                	mv	a4,s8
    80004900:	02092683          	lw	a3,32(s2)
    80004904:	01598633          	add	a2,s3,s5
    80004908:	4585                	li	a1,1
    8000490a:	01893503          	ld	a0,24(s2)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	266080e7          	jalr	614(ra) # 80003b74 <writei>
    80004916:	84aa                	mv	s1,a0
    80004918:	00a05763          	blez	a0,80004926 <filewrite+0xc4>
        f->off += r;
    8000491c:	02092783          	lw	a5,32(s2)
    80004920:	9fa9                	addw	a5,a5,a0
    80004922:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004926:	01893503          	ld	a0,24(s2)
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	f60080e7          	jalr	-160(ra) # 8000388a <iunlock>
      end_op();
    80004932:	00000097          	auipc	ra,0x0
    80004936:	8e8080e7          	jalr	-1816(ra) # 8000421a <end_op>

      if(r != n1){
    8000493a:	009c1f63          	bne	s8,s1,80004958 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000493e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004942:	0149db63          	bge	s3,s4,80004958 <filewrite+0xf6>
      int n1 = n - i;
    80004946:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000494a:	84be                	mv	s1,a5
    8000494c:	2781                	sext.w	a5,a5
    8000494e:	f8fb5ce3          	bge	s6,a5,800048e6 <filewrite+0x84>
    80004952:	84de                	mv	s1,s7
    80004954:	bf49                	j	800048e6 <filewrite+0x84>
    int i = 0;
    80004956:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004958:	013a1f63          	bne	s4,s3,80004976 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000495c:	8552                	mv	a0,s4
    8000495e:	60a6                	ld	ra,72(sp)
    80004960:	6406                	ld	s0,64(sp)
    80004962:	74e2                	ld	s1,56(sp)
    80004964:	7942                	ld	s2,48(sp)
    80004966:	79a2                	ld	s3,40(sp)
    80004968:	7a02                	ld	s4,32(sp)
    8000496a:	6ae2                	ld	s5,24(sp)
    8000496c:	6b42                	ld	s6,16(sp)
    8000496e:	6ba2                	ld	s7,8(sp)
    80004970:	6c02                	ld	s8,0(sp)
    80004972:	6161                	addi	sp,sp,80
    80004974:	8082                	ret
    ret = (i == n ? n : -1);
    80004976:	5a7d                	li	s4,-1
    80004978:	b7d5                	j	8000495c <filewrite+0xfa>
    panic("filewrite");
    8000497a:	00004517          	auipc	a0,0x4
    8000497e:	d2650513          	addi	a0,a0,-730 # 800086a0 <syscalls+0x270>
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	bae080e7          	jalr	-1106(ra) # 80000530 <panic>
    return -1;
    8000498a:	5a7d                	li	s4,-1
    8000498c:	bfc1                	j	8000495c <filewrite+0xfa>
      return -1;
    8000498e:	5a7d                	li	s4,-1
    80004990:	b7f1                	j	8000495c <filewrite+0xfa>
    80004992:	5a7d                	li	s4,-1
    80004994:	b7e1                	j	8000495c <filewrite+0xfa>

0000000080004996 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004996:	7179                	addi	sp,sp,-48
    80004998:	f406                	sd	ra,40(sp)
    8000499a:	f022                	sd	s0,32(sp)
    8000499c:	ec26                	sd	s1,24(sp)
    8000499e:	e84a                	sd	s2,16(sp)
    800049a0:	e44e                	sd	s3,8(sp)
    800049a2:	e052                	sd	s4,0(sp)
    800049a4:	1800                	addi	s0,sp,48
    800049a6:	84aa                	mv	s1,a0
    800049a8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049aa:	0005b023          	sd	zero,0(a1)
    800049ae:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	bf8080e7          	jalr	-1032(ra) # 800045aa <filealloc>
    800049ba:	e088                	sd	a0,0(s1)
    800049bc:	c551                	beqz	a0,80004a48 <pipealloc+0xb2>
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	bec080e7          	jalr	-1044(ra) # 800045aa <filealloc>
    800049c6:	00aa3023          	sd	a0,0(s4)
    800049ca:	c92d                	beqz	a0,80004a3c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	11a080e7          	jalr	282(ra) # 80000ae6 <kalloc>
    800049d4:	892a                	mv	s2,a0
    800049d6:	c125                	beqz	a0,80004a36 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049d8:	4985                	li	s3,1
    800049da:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049de:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049e2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049e6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ea:	00004597          	auipc	a1,0x4
    800049ee:	cc658593          	addi	a1,a1,-826 # 800086b0 <syscalls+0x280>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	154080e7          	jalr	340(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049fa:	609c                	ld	a5,0(s1)
    800049fc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a00:	609c                	ld	a5,0(s1)
    80004a02:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a06:	609c                	ld	a5,0(s1)
    80004a08:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a0c:	609c                	ld	a5,0(s1)
    80004a0e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a12:	000a3783          	ld	a5,0(s4)
    80004a16:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a1a:	000a3783          	ld	a5,0(s4)
    80004a1e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a22:	000a3783          	ld	a5,0(s4)
    80004a26:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a2a:	000a3783          	ld	a5,0(s4)
    80004a2e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a32:	4501                	li	a0,0
    80004a34:	a025                	j	80004a5c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a36:	6088                	ld	a0,0(s1)
    80004a38:	e501                	bnez	a0,80004a40 <pipealloc+0xaa>
    80004a3a:	a039                	j	80004a48 <pipealloc+0xb2>
    80004a3c:	6088                	ld	a0,0(s1)
    80004a3e:	c51d                	beqz	a0,80004a6c <pipealloc+0xd6>
    fileclose(*f0);
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	c26080e7          	jalr	-986(ra) # 80004666 <fileclose>
  if(*f1)
    80004a48:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a4c:	557d                	li	a0,-1
  if(*f1)
    80004a4e:	c799                	beqz	a5,80004a5c <pipealloc+0xc6>
    fileclose(*f1);
    80004a50:	853e                	mv	a0,a5
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	c14080e7          	jalr	-1004(ra) # 80004666 <fileclose>
  return -1;
    80004a5a:	557d                	li	a0,-1
}
    80004a5c:	70a2                	ld	ra,40(sp)
    80004a5e:	7402                	ld	s0,32(sp)
    80004a60:	64e2                	ld	s1,24(sp)
    80004a62:	6942                	ld	s2,16(sp)
    80004a64:	69a2                	ld	s3,8(sp)
    80004a66:	6a02                	ld	s4,0(sp)
    80004a68:	6145                	addi	sp,sp,48
    80004a6a:	8082                	ret
  return -1;
    80004a6c:	557d                	li	a0,-1
    80004a6e:	b7fd                	j	80004a5c <pipealloc+0xc6>

0000000080004a70 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a70:	1101                	addi	sp,sp,-32
    80004a72:	ec06                	sd	ra,24(sp)
    80004a74:	e822                	sd	s0,16(sp)
    80004a76:	e426                	sd	s1,8(sp)
    80004a78:	e04a                	sd	s2,0(sp)
    80004a7a:	1000                	addi	s0,sp,32
    80004a7c:	84aa                	mv	s1,a0
    80004a7e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	156080e7          	jalr	342(ra) # 80000bd6 <acquire>
  if(writable){
    80004a88:	02090d63          	beqz	s2,80004ac2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a8c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a90:	21848513          	addi	a0,s1,536
    80004a94:	ffffd097          	auipc	ra,0xffffd
    80004a98:	7b4080e7          	jalr	1972(ra) # 80002248 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a9c:	2204b783          	ld	a5,544(s1)
    80004aa0:	eb95                	bnez	a5,80004ad4 <pipeclose+0x64>
    release(&pi->lock);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1e6080e7          	jalr	486(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	f3c080e7          	jalr	-196(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004ab6:	60e2                	ld	ra,24(sp)
    80004ab8:	6442                	ld	s0,16(sp)
    80004aba:	64a2                	ld	s1,8(sp)
    80004abc:	6902                	ld	s2,0(sp)
    80004abe:	6105                	addi	sp,sp,32
    80004ac0:	8082                	ret
    pi->readopen = 0;
    80004ac2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ac6:	21c48513          	addi	a0,s1,540
    80004aca:	ffffd097          	auipc	ra,0xffffd
    80004ace:	77e080e7          	jalr	1918(ra) # 80002248 <wakeup>
    80004ad2:	b7e9                	j	80004a9c <pipeclose+0x2c>
    release(&pi->lock);
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	1b4080e7          	jalr	436(ra) # 80000c8a <release>
}
    80004ade:	bfe1                	j	80004ab6 <pipeclose+0x46>

0000000080004ae0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ae0:	7159                	addi	sp,sp,-112
    80004ae2:	f486                	sd	ra,104(sp)
    80004ae4:	f0a2                	sd	s0,96(sp)
    80004ae6:	eca6                	sd	s1,88(sp)
    80004ae8:	e8ca                	sd	s2,80(sp)
    80004aea:	e4ce                	sd	s3,72(sp)
    80004aec:	e0d2                	sd	s4,64(sp)
    80004aee:	fc56                	sd	s5,56(sp)
    80004af0:	f85a                	sd	s6,48(sp)
    80004af2:	f45e                	sd	s7,40(sp)
    80004af4:	f062                	sd	s8,32(sp)
    80004af6:	ec66                	sd	s9,24(sp)
    80004af8:	1880                	addi	s0,sp,112
    80004afa:	84aa                	mv	s1,a0
    80004afc:	8aae                	mv	s5,a1
    80004afe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	e94080e7          	jalr	-364(ra) # 80001994 <myproc>
    80004b08:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	0ca080e7          	jalr	202(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b14:	0d405163          	blez	s4,80004bd6 <pipewrite+0xf6>
    80004b18:	8ba6                	mv	s7,s1
  int i = 0;
    80004b1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b1e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b22:	21c48c13          	addi	s8,s1,540
    80004b26:	a08d                	j	80004b88 <pipewrite+0xa8>
      release(&pi->lock);
    80004b28:	8526                	mv	a0,s1
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	160080e7          	jalr	352(ra) # 80000c8a <release>
      return -1;
    80004b32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b34:	854a                	mv	a0,s2
    80004b36:	70a6                	ld	ra,104(sp)
    80004b38:	7406                	ld	s0,96(sp)
    80004b3a:	64e6                	ld	s1,88(sp)
    80004b3c:	6946                	ld	s2,80(sp)
    80004b3e:	69a6                	ld	s3,72(sp)
    80004b40:	6a06                	ld	s4,64(sp)
    80004b42:	7ae2                	ld	s5,56(sp)
    80004b44:	7b42                	ld	s6,48(sp)
    80004b46:	7ba2                	ld	s7,40(sp)
    80004b48:	7c02                	ld	s8,32(sp)
    80004b4a:	6ce2                	ld	s9,24(sp)
    80004b4c:	6165                	addi	sp,sp,112
    80004b4e:	8082                	ret
      wakeup(&pi->nread);
    80004b50:	8566                	mv	a0,s9
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	6f6080e7          	jalr	1782(ra) # 80002248 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b5a:	85de                	mv	a1,s7
    80004b5c:	8562                	mv	a0,s8
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	55e080e7          	jalr	1374(ra) # 800020bc <sleep>
    80004b66:	a839                	j	80004b84 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b68:	21c4a783          	lw	a5,540(s1)
    80004b6c:	0017871b          	addiw	a4,a5,1
    80004b70:	20e4ae23          	sw	a4,540(s1)
    80004b74:	1ff7f793          	andi	a5,a5,511
    80004b78:	97a6                	add	a5,a5,s1
    80004b7a:	f9f44703          	lbu	a4,-97(s0)
    80004b7e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b82:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b84:	03495d63          	bge	s2,s4,80004bbe <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b88:	2204a783          	lw	a5,544(s1)
    80004b8c:	dfd1                	beqz	a5,80004b28 <pipewrite+0x48>
    80004b8e:	0289a783          	lw	a5,40(s3)
    80004b92:	fbd9                	bnez	a5,80004b28 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b94:	2184a783          	lw	a5,536(s1)
    80004b98:	21c4a703          	lw	a4,540(s1)
    80004b9c:	2007879b          	addiw	a5,a5,512
    80004ba0:	faf708e3          	beq	a4,a5,80004b50 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba4:	4685                	li	a3,1
    80004ba6:	01590633          	add	a2,s2,s5
    80004baa:	f9f40593          	addi	a1,s0,-97
    80004bae:	0509b503          	ld	a0,80(s3)
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	b30080e7          	jalr	-1232(ra) # 800016e2 <copyin>
    80004bba:	fb6517e3          	bne	a0,s6,80004b68 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bbe:	21848513          	addi	a0,s1,536
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	686080e7          	jalr	1670(ra) # 80002248 <wakeup>
  release(&pi->lock);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	0be080e7          	jalr	190(ra) # 80000c8a <release>
  return i;
    80004bd4:	b785                	j	80004b34 <pipewrite+0x54>
  int i = 0;
    80004bd6:	4901                	li	s2,0
    80004bd8:	b7dd                	j	80004bbe <pipewrite+0xde>

0000000080004bda <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bda:	715d                	addi	sp,sp,-80
    80004bdc:	e486                	sd	ra,72(sp)
    80004bde:	e0a2                	sd	s0,64(sp)
    80004be0:	fc26                	sd	s1,56(sp)
    80004be2:	f84a                	sd	s2,48(sp)
    80004be4:	f44e                	sd	s3,40(sp)
    80004be6:	f052                	sd	s4,32(sp)
    80004be8:	ec56                	sd	s5,24(sp)
    80004bea:	e85a                	sd	s6,16(sp)
    80004bec:	0880                	addi	s0,sp,80
    80004bee:	84aa                	mv	s1,a0
    80004bf0:	892e                	mv	s2,a1
    80004bf2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	da0080e7          	jalr	-608(ra) # 80001994 <myproc>
    80004bfc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bfe:	8b26                	mv	s6,s1
    80004c00:	8526                	mv	a0,s1
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	fd4080e7          	jalr	-44(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c0a:	2184a703          	lw	a4,536(s1)
    80004c0e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c12:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c16:	02f71463          	bne	a4,a5,80004c3e <piperead+0x64>
    80004c1a:	2244a783          	lw	a5,548(s1)
    80004c1e:	c385                	beqz	a5,80004c3e <piperead+0x64>
    if(pr->killed){
    80004c20:	028a2783          	lw	a5,40(s4)
    80004c24:	ebc1                	bnez	a5,80004cb4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c26:	85da                	mv	a1,s6
    80004c28:	854e                	mv	a0,s3
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	492080e7          	jalr	1170(ra) # 800020bc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c32:	2184a703          	lw	a4,536(s1)
    80004c36:	21c4a783          	lw	a5,540(s1)
    80004c3a:	fef700e3          	beq	a4,a5,80004c1a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c3e:	09505263          	blez	s5,80004cc2 <piperead+0xe8>
    80004c42:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c44:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c46:	2184a783          	lw	a5,536(s1)
    80004c4a:	21c4a703          	lw	a4,540(s1)
    80004c4e:	02f70d63          	beq	a4,a5,80004c88 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c52:	0017871b          	addiw	a4,a5,1
    80004c56:	20e4ac23          	sw	a4,536(s1)
    80004c5a:	1ff7f793          	andi	a5,a5,511
    80004c5e:	97a6                	add	a5,a5,s1
    80004c60:	0187c783          	lbu	a5,24(a5)
    80004c64:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c68:	4685                	li	a3,1
    80004c6a:	fbf40613          	addi	a2,s0,-65
    80004c6e:	85ca                	mv	a1,s2
    80004c70:	050a3503          	ld	a0,80(s4)
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	9e2080e7          	jalr	-1566(ra) # 80001656 <copyout>
    80004c7c:	01650663          	beq	a0,s6,80004c88 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c80:	2985                	addiw	s3,s3,1
    80004c82:	0905                	addi	s2,s2,1
    80004c84:	fd3a91e3          	bne	s5,s3,80004c46 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c88:	21c48513          	addi	a0,s1,540
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	5bc080e7          	jalr	1468(ra) # 80002248 <wakeup>
  release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
  return i;
}
    80004c9e:	854e                	mv	a0,s3
    80004ca0:	60a6                	ld	ra,72(sp)
    80004ca2:	6406                	ld	s0,64(sp)
    80004ca4:	74e2                	ld	s1,56(sp)
    80004ca6:	7942                	ld	s2,48(sp)
    80004ca8:	79a2                	ld	s3,40(sp)
    80004caa:	7a02                	ld	s4,32(sp)
    80004cac:	6ae2                	ld	s5,24(sp)
    80004cae:	6b42                	ld	s6,16(sp)
    80004cb0:	6161                	addi	sp,sp,80
    80004cb2:	8082                	ret
      release(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fd4080e7          	jalr	-44(ra) # 80000c8a <release>
      return -1;
    80004cbe:	59fd                	li	s3,-1
    80004cc0:	bff9                	j	80004c9e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc2:	4981                	li	s3,0
    80004cc4:	b7d1                	j	80004c88 <piperead+0xae>

0000000080004cc6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cc6:	df010113          	addi	sp,sp,-528
    80004cca:	20113423          	sd	ra,520(sp)
    80004cce:	20813023          	sd	s0,512(sp)
    80004cd2:	ffa6                	sd	s1,504(sp)
    80004cd4:	fbca                	sd	s2,496(sp)
    80004cd6:	f7ce                	sd	s3,488(sp)
    80004cd8:	f3d2                	sd	s4,480(sp)
    80004cda:	efd6                	sd	s5,472(sp)
    80004cdc:	ebda                	sd	s6,464(sp)
    80004cde:	e7de                	sd	s7,456(sp)
    80004ce0:	e3e2                	sd	s8,448(sp)
    80004ce2:	ff66                	sd	s9,440(sp)
    80004ce4:	fb6a                	sd	s10,432(sp)
    80004ce6:	f76e                	sd	s11,424(sp)
    80004ce8:	0c00                	addi	s0,sp,528
    80004cea:	84aa                	mv	s1,a0
    80004cec:	dea43c23          	sd	a0,-520(s0)
    80004cf0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	ca0080e7          	jalr	-864(ra) # 80001994 <myproc>
    80004cfc:	892a                	mv	s2,a0

  begin_op();
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	49c080e7          	jalr	1180(ra) # 8000419a <begin_op>

  if((ip = namei(path)) == 0){
    80004d06:	8526                	mv	a0,s1
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	276080e7          	jalr	630(ra) # 80003f7e <namei>
    80004d10:	c92d                	beqz	a0,80004d82 <exec+0xbc>
    80004d12:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	ab4080e7          	jalr	-1356(ra) # 800037c8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d1c:	04000713          	li	a4,64
    80004d20:	4681                	li	a3,0
    80004d22:	e4840613          	addi	a2,s0,-440
    80004d26:	4581                	li	a1,0
    80004d28:	8526                	mv	a0,s1
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	d52080e7          	jalr	-686(ra) # 80003a7c <readi>
    80004d32:	04000793          	li	a5,64
    80004d36:	00f51a63          	bne	a0,a5,80004d4a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d3a:	e4842703          	lw	a4,-440(s0)
    80004d3e:	464c47b7          	lui	a5,0x464c4
    80004d42:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d46:	04f70463          	beq	a4,a5,80004d8e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d4a:	8526                	mv	a0,s1
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	cde080e7          	jalr	-802(ra) # 80003a2a <iunlockput>
    end_op();
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	4c6080e7          	jalr	1222(ra) # 8000421a <end_op>
  }
  return -1;
    80004d5c:	557d                	li	a0,-1
}
    80004d5e:	20813083          	ld	ra,520(sp)
    80004d62:	20013403          	ld	s0,512(sp)
    80004d66:	74fe                	ld	s1,504(sp)
    80004d68:	795e                	ld	s2,496(sp)
    80004d6a:	79be                	ld	s3,488(sp)
    80004d6c:	7a1e                	ld	s4,480(sp)
    80004d6e:	6afe                	ld	s5,472(sp)
    80004d70:	6b5e                	ld	s6,464(sp)
    80004d72:	6bbe                	ld	s7,456(sp)
    80004d74:	6c1e                	ld	s8,448(sp)
    80004d76:	7cfa                	ld	s9,440(sp)
    80004d78:	7d5a                	ld	s10,432(sp)
    80004d7a:	7dba                	ld	s11,424(sp)
    80004d7c:	21010113          	addi	sp,sp,528
    80004d80:	8082                	ret
    end_op();
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	498080e7          	jalr	1176(ra) # 8000421a <end_op>
    return -1;
    80004d8a:	557d                	li	a0,-1
    80004d8c:	bfc9                	j	80004d5e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d8e:	854a                	mv	a0,s2
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	cc8080e7          	jalr	-824(ra) # 80001a58 <proc_pagetable>
    80004d98:	8baa                	mv	s7,a0
    80004d9a:	d945                	beqz	a0,80004d4a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9c:	e6842983          	lw	s3,-408(s0)
    80004da0:	e8045783          	lhu	a5,-384(s0)
    80004da4:	c7ad                	beqz	a5,80004e0e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004da6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004daa:	6c85                	lui	s9,0x1
    80004dac:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004db0:	def43823          	sd	a5,-528(s0)
    80004db4:	a42d                	j	80004fde <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004db6:	00004517          	auipc	a0,0x4
    80004dba:	90250513          	addi	a0,a0,-1790 # 800086b8 <syscalls+0x288>
    80004dbe:	ffffb097          	auipc	ra,0xffffb
    80004dc2:	772080e7          	jalr	1906(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dc6:	8756                	mv	a4,s5
    80004dc8:	012d86bb          	addw	a3,s11,s2
    80004dcc:	4581                	li	a1,0
    80004dce:	8526                	mv	a0,s1
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	cac080e7          	jalr	-852(ra) # 80003a7c <readi>
    80004dd8:	2501                	sext.w	a0,a0
    80004dda:	1aaa9963          	bne	s5,a0,80004f8c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dde:	6785                	lui	a5,0x1
    80004de0:	0127893b          	addw	s2,a5,s2
    80004de4:	77fd                	lui	a5,0xfffff
    80004de6:	01478a3b          	addw	s4,a5,s4
    80004dea:	1f897163          	bgeu	s2,s8,80004fcc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dee:	02091593          	slli	a1,s2,0x20
    80004df2:	9181                	srli	a1,a1,0x20
    80004df4:	95ea                	add	a1,a1,s10
    80004df6:	855e                	mv	a0,s7
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	26c080e7          	jalr	620(ra) # 80001064 <walkaddr>
    80004e00:	862a                	mv	a2,a0
    if(pa == 0)
    80004e02:	d955                	beqz	a0,80004db6 <exec+0xf0>
      n = PGSIZE;
    80004e04:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e06:	fd9a70e3          	bgeu	s4,s9,80004dc6 <exec+0x100>
      n = sz - i;
    80004e0a:	8ad2                	mv	s5,s4
    80004e0c:	bf6d                	j	80004dc6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e0e:	4901                	li	s2,0
  iunlockput(ip);
    80004e10:	8526                	mv	a0,s1
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	c18080e7          	jalr	-1000(ra) # 80003a2a <iunlockput>
  end_op();
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	400080e7          	jalr	1024(ra) # 8000421a <end_op>
  p = myproc();
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	b72080e7          	jalr	-1166(ra) # 80001994 <myproc>
    80004e2a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e2c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e30:	6785                	lui	a5,0x1
    80004e32:	17fd                	addi	a5,a5,-1
    80004e34:	993e                	add	s2,s2,a5
    80004e36:	757d                	lui	a0,0xfffff
    80004e38:	00a977b3          	and	a5,s2,a0
    80004e3c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e40:	6609                	lui	a2,0x2
    80004e42:	963e                	add	a2,a2,a5
    80004e44:	85be                	mv	a1,a5
    80004e46:	855e                	mv	a0,s7
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	5be080e7          	jalr	1470(ra) # 80001406 <uvmalloc>
    80004e50:	8b2a                	mv	s6,a0
  ip = 0;
    80004e52:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e54:	12050c63          	beqz	a0,80004f8c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e58:	75f9                	lui	a1,0xffffe
    80004e5a:	95aa                	add	a1,a1,a0
    80004e5c:	855e                	mv	a0,s7
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	7c6080e7          	jalr	1990(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e66:	7c7d                	lui	s8,0xfffff
    80004e68:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6a:	e0043783          	ld	a5,-512(s0)
    80004e6e:	6388                	ld	a0,0(a5)
    80004e70:	c535                	beqz	a0,80004edc <exec+0x216>
    80004e72:	e8840993          	addi	s3,s0,-376
    80004e76:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e7a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	fde080e7          	jalr	-34(ra) # 80000e5a <strlen>
    80004e84:	2505                	addiw	a0,a0,1
    80004e86:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e8e:	13896363          	bltu	s2,s8,80004fb4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e92:	e0043d83          	ld	s11,-512(s0)
    80004e96:	000dba03          	ld	s4,0(s11)
    80004e9a:	8552                	mv	a0,s4
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	fbe080e7          	jalr	-66(ra) # 80000e5a <strlen>
    80004ea4:	0015069b          	addiw	a3,a0,1
    80004ea8:	8652                	mv	a2,s4
    80004eaa:	85ca                	mv	a1,s2
    80004eac:	855e                	mv	a0,s7
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	7a8080e7          	jalr	1960(ra) # 80001656 <copyout>
    80004eb6:	10054363          	bltz	a0,80004fbc <exec+0x2f6>
    ustack[argc] = sp;
    80004eba:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ebe:	0485                	addi	s1,s1,1
    80004ec0:	008d8793          	addi	a5,s11,8
    80004ec4:	e0f43023          	sd	a5,-512(s0)
    80004ec8:	008db503          	ld	a0,8(s11)
    80004ecc:	c911                	beqz	a0,80004ee0 <exec+0x21a>
    if(argc >= MAXARG)
    80004ece:	09a1                	addi	s3,s3,8
    80004ed0:	fb3c96e3          	bne	s9,s3,80004e7c <exec+0x1b6>
  sz = sz1;
    80004ed4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ed8:	4481                	li	s1,0
    80004eda:	a84d                	j	80004f8c <exec+0x2c6>
  sp = sz;
    80004edc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ede:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee0:	00349793          	slli	a5,s1,0x3
    80004ee4:	f9040713          	addi	a4,s0,-112
    80004ee8:	97ba                	add	a5,a5,a4
    80004eea:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004eee:	00148693          	addi	a3,s1,1
    80004ef2:	068e                	slli	a3,a3,0x3
    80004ef4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ef8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004efc:	01897663          	bgeu	s2,s8,80004f08 <exec+0x242>
  sz = sz1;
    80004f00:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f04:	4481                	li	s1,0
    80004f06:	a059                	j	80004f8c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f08:	e8840613          	addi	a2,s0,-376
    80004f0c:	85ca                	mv	a1,s2
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	746080e7          	jalr	1862(ra) # 80001656 <copyout>
    80004f18:	0a054663          	bltz	a0,80004fc4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f1c:	058ab783          	ld	a5,88(s5)
    80004f20:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f24:	df843783          	ld	a5,-520(s0)
    80004f28:	0007c703          	lbu	a4,0(a5)
    80004f2c:	cf11                	beqz	a4,80004f48 <exec+0x282>
    80004f2e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f30:	02f00693          	li	a3,47
    80004f34:	a029                	j	80004f3e <exec+0x278>
  for(last=s=path; *s; s++)
    80004f36:	0785                	addi	a5,a5,1
    80004f38:	fff7c703          	lbu	a4,-1(a5)
    80004f3c:	c711                	beqz	a4,80004f48 <exec+0x282>
    if(*s == '/')
    80004f3e:	fed71ce3          	bne	a4,a3,80004f36 <exec+0x270>
      last = s+1;
    80004f42:	def43c23          	sd	a5,-520(s0)
    80004f46:	bfc5                	j	80004f36 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f48:	4641                	li	a2,16
    80004f4a:	df843583          	ld	a1,-520(s0)
    80004f4e:	160a8513          	addi	a0,s5,352
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	ed6080e7          	jalr	-298(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f5e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f62:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f66:	058ab783          	ld	a5,88(s5)
    80004f6a:	e6043703          	ld	a4,-416(s0)
    80004f6e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f70:	058ab783          	ld	a5,88(s5)
    80004f74:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f78:	85ea                	mv	a1,s10
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	b7a080e7          	jalr	-1158(ra) # 80001af4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f82:	0004851b          	sext.w	a0,s1
    80004f86:	bbe1                	j	80004d5e <exec+0x98>
    80004f88:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f8c:	e0843583          	ld	a1,-504(s0)
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	b62080e7          	jalr	-1182(ra) # 80001af4 <proc_freepagetable>
  if(ip){
    80004f9a:	da0498e3          	bnez	s1,80004d4a <exec+0x84>
  return -1;
    80004f9e:	557d                	li	a0,-1
    80004fa0:	bb7d                	j	80004d5e <exec+0x98>
    80004fa2:	e1243423          	sd	s2,-504(s0)
    80004fa6:	b7dd                	j	80004f8c <exec+0x2c6>
    80004fa8:	e1243423          	sd	s2,-504(s0)
    80004fac:	b7c5                	j	80004f8c <exec+0x2c6>
    80004fae:	e1243423          	sd	s2,-504(s0)
    80004fb2:	bfe9                	j	80004f8c <exec+0x2c6>
  sz = sz1;
    80004fb4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb8:	4481                	li	s1,0
    80004fba:	bfc9                	j	80004f8c <exec+0x2c6>
  sz = sz1;
    80004fbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	b7e9                	j	80004f8c <exec+0x2c6>
  sz = sz1;
    80004fc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc8:	4481                	li	s1,0
    80004fca:	b7c9                	j	80004f8c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fcc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd0:	2b05                	addiw	s6,s6,1
    80004fd2:	0389899b          	addiw	s3,s3,56
    80004fd6:	e8045783          	lhu	a5,-384(s0)
    80004fda:	e2fb5be3          	bge	s6,a5,80004e10 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fde:	2981                	sext.w	s3,s3
    80004fe0:	03800713          	li	a4,56
    80004fe4:	86ce                	mv	a3,s3
    80004fe6:	e1040613          	addi	a2,s0,-496
    80004fea:	4581                	li	a1,0
    80004fec:	8526                	mv	a0,s1
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	a8e080e7          	jalr	-1394(ra) # 80003a7c <readi>
    80004ff6:	03800793          	li	a5,56
    80004ffa:	f8f517e3          	bne	a0,a5,80004f88 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004ffe:	e1042783          	lw	a5,-496(s0)
    80005002:	4705                	li	a4,1
    80005004:	fce796e3          	bne	a5,a4,80004fd0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005008:	e3843603          	ld	a2,-456(s0)
    8000500c:	e3043783          	ld	a5,-464(s0)
    80005010:	f8f669e3          	bltu	a2,a5,80004fa2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005014:	e2043783          	ld	a5,-480(s0)
    80005018:	963e                	add	a2,a2,a5
    8000501a:	f8f667e3          	bltu	a2,a5,80004fa8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000501e:	85ca                	mv	a1,s2
    80005020:	855e                	mv	a0,s7
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	3e4080e7          	jalr	996(ra) # 80001406 <uvmalloc>
    8000502a:	e0a43423          	sd	a0,-504(s0)
    8000502e:	d141                	beqz	a0,80004fae <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005030:	e2043d03          	ld	s10,-480(s0)
    80005034:	df043783          	ld	a5,-528(s0)
    80005038:	00fd77b3          	and	a5,s10,a5
    8000503c:	fba1                	bnez	a5,80004f8c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000503e:	e1842d83          	lw	s11,-488(s0)
    80005042:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005046:	f80c03e3          	beqz	s8,80004fcc <exec+0x306>
    8000504a:	8a62                	mv	s4,s8
    8000504c:	4901                	li	s2,0
    8000504e:	b345                	j	80004dee <exec+0x128>

0000000080005050 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005050:	7179                	addi	sp,sp,-48
    80005052:	f406                	sd	ra,40(sp)
    80005054:	f022                	sd	s0,32(sp)
    80005056:	ec26                	sd	s1,24(sp)
    80005058:	e84a                	sd	s2,16(sp)
    8000505a:	1800                	addi	s0,sp,48
    8000505c:	892e                	mv	s2,a1
    8000505e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005060:	fdc40593          	addi	a1,s0,-36
    80005064:	ffffe097          	auipc	ra,0xffffe
    80005068:	bc0080e7          	jalr	-1088(ra) # 80002c24 <argint>
    8000506c:	04054063          	bltz	a0,800050ac <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005070:	fdc42703          	lw	a4,-36(s0)
    80005074:	47bd                	li	a5,15
    80005076:	02e7ed63          	bltu	a5,a4,800050b0 <argfd+0x60>
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	91a080e7          	jalr	-1766(ra) # 80001994 <myproc>
    80005082:	fdc42703          	lw	a4,-36(s0)
    80005086:	01a70793          	addi	a5,a4,26
    8000508a:	078e                	slli	a5,a5,0x3
    8000508c:	953e                	add	a0,a0,a5
    8000508e:	611c                	ld	a5,0(a0)
    80005090:	c395                	beqz	a5,800050b4 <argfd+0x64>
    return -1;
  if(pfd)
    80005092:	00090463          	beqz	s2,8000509a <argfd+0x4a>
    *pfd = fd;
    80005096:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000509a:	4501                	li	a0,0
  if(pf)
    8000509c:	c091                	beqz	s1,800050a0 <argfd+0x50>
    *pf = f;
    8000509e:	e09c                	sd	a5,0(s1)
}
    800050a0:	70a2                	ld	ra,40(sp)
    800050a2:	7402                	ld	s0,32(sp)
    800050a4:	64e2                	ld	s1,24(sp)
    800050a6:	6942                	ld	s2,16(sp)
    800050a8:	6145                	addi	sp,sp,48
    800050aa:	8082                	ret
    return -1;
    800050ac:	557d                	li	a0,-1
    800050ae:	bfcd                	j	800050a0 <argfd+0x50>
    return -1;
    800050b0:	557d                	li	a0,-1
    800050b2:	b7fd                	j	800050a0 <argfd+0x50>
    800050b4:	557d                	li	a0,-1
    800050b6:	b7ed                	j	800050a0 <argfd+0x50>

00000000800050b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050b8:	1101                	addi	sp,sp,-32
    800050ba:	ec06                	sd	ra,24(sp)
    800050bc:	e822                	sd	s0,16(sp)
    800050be:	e426                	sd	s1,8(sp)
    800050c0:	1000                	addi	s0,sp,32
    800050c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	8d0080e7          	jalr	-1840(ra) # 80001994 <myproc>
    800050cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ce:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050d2:	4501                	li	a0,0
    800050d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050d6:	6398                	ld	a4,0(a5)
    800050d8:	cb19                	beqz	a4,800050ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050da:	2505                	addiw	a0,a0,1
    800050dc:	07a1                	addi	a5,a5,8
    800050de:	fed51ce3          	bne	a0,a3,800050d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050e2:	557d                	li	a0,-1
}
    800050e4:	60e2                	ld	ra,24(sp)
    800050e6:	6442                	ld	s0,16(sp)
    800050e8:	64a2                	ld	s1,8(sp)
    800050ea:	6105                	addi	sp,sp,32
    800050ec:	8082                	ret
      p->ofile[fd] = f;
    800050ee:	01a50793          	addi	a5,a0,26
    800050f2:	078e                	slli	a5,a5,0x3
    800050f4:	963e                	add	a2,a2,a5
    800050f6:	e204                	sd	s1,0(a2)
      return fd;
    800050f8:	b7f5                	j	800050e4 <fdalloc+0x2c>

00000000800050fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050fa:	715d                	addi	sp,sp,-80
    800050fc:	e486                	sd	ra,72(sp)
    800050fe:	e0a2                	sd	s0,64(sp)
    80005100:	fc26                	sd	s1,56(sp)
    80005102:	f84a                	sd	s2,48(sp)
    80005104:	f44e                	sd	s3,40(sp)
    80005106:	f052                	sd	s4,32(sp)
    80005108:	ec56                	sd	s5,24(sp)
    8000510a:	0880                	addi	s0,sp,80
    8000510c:	89ae                	mv	s3,a1
    8000510e:	8ab2                	mv	s5,a2
    80005110:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005112:	fb040593          	addi	a1,s0,-80
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	e86080e7          	jalr	-378(ra) # 80003f9c <nameiparent>
    8000511e:	892a                	mv	s2,a0
    80005120:	12050f63          	beqz	a0,8000525e <create+0x164>
    return 0;

  ilock(dp);
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	6a4080e7          	jalr	1700(ra) # 800037c8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000512c:	4601                	li	a2,0
    8000512e:	fb040593          	addi	a1,s0,-80
    80005132:	854a                	mv	a0,s2
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	b78080e7          	jalr	-1160(ra) # 80003cac <dirlookup>
    8000513c:	84aa                	mv	s1,a0
    8000513e:	c921                	beqz	a0,8000518e <create+0x94>
    iunlockput(dp);
    80005140:	854a                	mv	a0,s2
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	8e8080e7          	jalr	-1816(ra) # 80003a2a <iunlockput>
    ilock(ip);
    8000514a:	8526                	mv	a0,s1
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	67c080e7          	jalr	1660(ra) # 800037c8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005154:	2981                	sext.w	s3,s3
    80005156:	4789                	li	a5,2
    80005158:	02f99463          	bne	s3,a5,80005180 <create+0x86>
    8000515c:	0444d783          	lhu	a5,68(s1)
    80005160:	37f9                	addiw	a5,a5,-2
    80005162:	17c2                	slli	a5,a5,0x30
    80005164:	93c1                	srli	a5,a5,0x30
    80005166:	4705                	li	a4,1
    80005168:	00f76c63          	bltu	a4,a5,80005180 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000516c:	8526                	mv	a0,s1
    8000516e:	60a6                	ld	ra,72(sp)
    80005170:	6406                	ld	s0,64(sp)
    80005172:	74e2                	ld	s1,56(sp)
    80005174:	7942                	ld	s2,48(sp)
    80005176:	79a2                	ld	s3,40(sp)
    80005178:	7a02                	ld	s4,32(sp)
    8000517a:	6ae2                	ld	s5,24(sp)
    8000517c:	6161                	addi	sp,sp,80
    8000517e:	8082                	ret
    iunlockput(ip);
    80005180:	8526                	mv	a0,s1
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	8a8080e7          	jalr	-1880(ra) # 80003a2a <iunlockput>
    return 0;
    8000518a:	4481                	li	s1,0
    8000518c:	b7c5                	j	8000516c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000518e:	85ce                	mv	a1,s3
    80005190:	00092503          	lw	a0,0(s2)
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	49c080e7          	jalr	1180(ra) # 80003630 <ialloc>
    8000519c:	84aa                	mv	s1,a0
    8000519e:	c529                	beqz	a0,800051e8 <create+0xee>
  ilock(ip);
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	628080e7          	jalr	1576(ra) # 800037c8 <ilock>
  ip->major = major;
    800051a8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051ac:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051b0:	4785                	li	a5,1
    800051b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051b6:	8526                	mv	a0,s1
    800051b8:	ffffe097          	auipc	ra,0xffffe
    800051bc:	546080e7          	jalr	1350(ra) # 800036fe <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051c0:	2981                	sext.w	s3,s3
    800051c2:	4785                	li	a5,1
    800051c4:	02f98a63          	beq	s3,a5,800051f8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051c8:	40d0                	lw	a2,4(s1)
    800051ca:	fb040593          	addi	a1,s0,-80
    800051ce:	854a                	mv	a0,s2
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	cec080e7          	jalr	-788(ra) # 80003ebc <dirlink>
    800051d8:	06054b63          	bltz	a0,8000524e <create+0x154>
  iunlockput(dp);
    800051dc:	854a                	mv	a0,s2
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	84c080e7          	jalr	-1972(ra) # 80003a2a <iunlockput>
  return ip;
    800051e6:	b759                	j	8000516c <create+0x72>
    panic("create: ialloc");
    800051e8:	00003517          	auipc	a0,0x3
    800051ec:	4f050513          	addi	a0,a0,1264 # 800086d8 <syscalls+0x2a8>
    800051f0:	ffffb097          	auipc	ra,0xffffb
    800051f4:	340080e7          	jalr	832(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    800051f8:	04a95783          	lhu	a5,74(s2)
    800051fc:	2785                	addiw	a5,a5,1
    800051fe:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005202:	854a                	mv	a0,s2
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	4fa080e7          	jalr	1274(ra) # 800036fe <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000520c:	40d0                	lw	a2,4(s1)
    8000520e:	00003597          	auipc	a1,0x3
    80005212:	4da58593          	addi	a1,a1,1242 # 800086e8 <syscalls+0x2b8>
    80005216:	8526                	mv	a0,s1
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	ca4080e7          	jalr	-860(ra) # 80003ebc <dirlink>
    80005220:	00054f63          	bltz	a0,8000523e <create+0x144>
    80005224:	00492603          	lw	a2,4(s2)
    80005228:	00003597          	auipc	a1,0x3
    8000522c:	4c858593          	addi	a1,a1,1224 # 800086f0 <syscalls+0x2c0>
    80005230:	8526                	mv	a0,s1
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	c8a080e7          	jalr	-886(ra) # 80003ebc <dirlink>
    8000523a:	f80557e3          	bgez	a0,800051c8 <create+0xce>
      panic("create dots");
    8000523e:	00003517          	auipc	a0,0x3
    80005242:	4ba50513          	addi	a0,a0,1210 # 800086f8 <syscalls+0x2c8>
    80005246:	ffffb097          	auipc	ra,0xffffb
    8000524a:	2ea080e7          	jalr	746(ra) # 80000530 <panic>
    panic("create: dirlink");
    8000524e:	00003517          	auipc	a0,0x3
    80005252:	4ba50513          	addi	a0,a0,1210 # 80008708 <syscalls+0x2d8>
    80005256:	ffffb097          	auipc	ra,0xffffb
    8000525a:	2da080e7          	jalr	730(ra) # 80000530 <panic>
    return 0;
    8000525e:	84aa                	mv	s1,a0
    80005260:	b731                	j	8000516c <create+0x72>

0000000080005262 <sys_dup>:
{
    80005262:	7179                	addi	sp,sp,-48
    80005264:	f406                	sd	ra,40(sp)
    80005266:	f022                	sd	s0,32(sp)
    80005268:	ec26                	sd	s1,24(sp)
    8000526a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000526c:	fd840613          	addi	a2,s0,-40
    80005270:	4581                	li	a1,0
    80005272:	4501                	li	a0,0
    80005274:	00000097          	auipc	ra,0x0
    80005278:	ddc080e7          	jalr	-548(ra) # 80005050 <argfd>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000527e:	02054363          	bltz	a0,800052a4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005282:	fd843503          	ld	a0,-40(s0)
    80005286:	00000097          	auipc	ra,0x0
    8000528a:	e32080e7          	jalr	-462(ra) # 800050b8 <fdalloc>
    8000528e:	84aa                	mv	s1,a0
    return -1;
    80005290:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005292:	00054963          	bltz	a0,800052a4 <sys_dup+0x42>
  filedup(f);
    80005296:	fd843503          	ld	a0,-40(s0)
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	37a080e7          	jalr	890(ra) # 80004614 <filedup>
  return fd;
    800052a2:	87a6                	mv	a5,s1
}
    800052a4:	853e                	mv	a0,a5
    800052a6:	70a2                	ld	ra,40(sp)
    800052a8:	7402                	ld	s0,32(sp)
    800052aa:	64e2                	ld	s1,24(sp)
    800052ac:	6145                	addi	sp,sp,48
    800052ae:	8082                	ret

00000000800052b0 <sys_read>:
{
    800052b0:	7179                	addi	sp,sp,-48
    800052b2:	f406                	sd	ra,40(sp)
    800052b4:	f022                	sd	s0,32(sp)
    800052b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b8:	fe840613          	addi	a2,s0,-24
    800052bc:	4581                	li	a1,0
    800052be:	4501                	li	a0,0
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	d90080e7          	jalr	-624(ra) # 80005050 <argfd>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ca:	04054163          	bltz	a0,8000530c <sys_read+0x5c>
    800052ce:	fe440593          	addi	a1,s0,-28
    800052d2:	4509                	li	a0,2
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	950080e7          	jalr	-1712(ra) # 80002c24 <argint>
    return -1;
    800052dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052de:	02054763          	bltz	a0,8000530c <sys_read+0x5c>
    800052e2:	fd840593          	addi	a1,s0,-40
    800052e6:	4505                	li	a0,1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	95e080e7          	jalr	-1698(ra) # 80002c46 <argaddr>
    return -1;
    800052f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f2:	00054d63          	bltz	a0,8000530c <sys_read+0x5c>
  return fileread(f, p, n);
    800052f6:	fe442603          	lw	a2,-28(s0)
    800052fa:	fd843583          	ld	a1,-40(s0)
    800052fe:	fe843503          	ld	a0,-24(s0)
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	49e080e7          	jalr	1182(ra) # 800047a0 <fileread>
    8000530a:	87aa                	mv	a5,a0
}
    8000530c:	853e                	mv	a0,a5
    8000530e:	70a2                	ld	ra,40(sp)
    80005310:	7402                	ld	s0,32(sp)
    80005312:	6145                	addi	sp,sp,48
    80005314:	8082                	ret

0000000080005316 <sys_write>:
{
    80005316:	7179                	addi	sp,sp,-48
    80005318:	f406                	sd	ra,40(sp)
    8000531a:	f022                	sd	s0,32(sp)
    8000531c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531e:	fe840613          	addi	a2,s0,-24
    80005322:	4581                	li	a1,0
    80005324:	4501                	li	a0,0
    80005326:	00000097          	auipc	ra,0x0
    8000532a:	d2a080e7          	jalr	-726(ra) # 80005050 <argfd>
    return -1;
    8000532e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005330:	04054163          	bltz	a0,80005372 <sys_write+0x5c>
    80005334:	fe440593          	addi	a1,s0,-28
    80005338:	4509                	li	a0,2
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	8ea080e7          	jalr	-1814(ra) # 80002c24 <argint>
    return -1;
    80005342:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	02054763          	bltz	a0,80005372 <sys_write+0x5c>
    80005348:	fd840593          	addi	a1,s0,-40
    8000534c:	4505                	li	a0,1
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	8f8080e7          	jalr	-1800(ra) # 80002c46 <argaddr>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005358:	00054d63          	bltz	a0,80005372 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000535c:	fe442603          	lw	a2,-28(s0)
    80005360:	fd843583          	ld	a1,-40(s0)
    80005364:	fe843503          	ld	a0,-24(s0)
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	4fa080e7          	jalr	1274(ra) # 80004862 <filewrite>
    80005370:	87aa                	mv	a5,a0
}
    80005372:	853e                	mv	a0,a5
    80005374:	70a2                	ld	ra,40(sp)
    80005376:	7402                	ld	s0,32(sp)
    80005378:	6145                	addi	sp,sp,48
    8000537a:	8082                	ret

000000008000537c <sys_close>:
{
    8000537c:	1101                	addi	sp,sp,-32
    8000537e:	ec06                	sd	ra,24(sp)
    80005380:	e822                	sd	s0,16(sp)
    80005382:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005384:	fe040613          	addi	a2,s0,-32
    80005388:	fec40593          	addi	a1,s0,-20
    8000538c:	4501                	li	a0,0
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	cc2080e7          	jalr	-830(ra) # 80005050 <argfd>
    return -1;
    80005396:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005398:	02054463          	bltz	a0,800053c0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	5f8080e7          	jalr	1528(ra) # 80001994 <myproc>
    800053a4:	fec42783          	lw	a5,-20(s0)
    800053a8:	07e9                	addi	a5,a5,26
    800053aa:	078e                	slli	a5,a5,0x3
    800053ac:	97aa                	add	a5,a5,a0
    800053ae:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053b2:	fe043503          	ld	a0,-32(s0)
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	2b0080e7          	jalr	688(ra) # 80004666 <fileclose>
  return 0;
    800053be:	4781                	li	a5,0
}
    800053c0:	853e                	mv	a0,a5
    800053c2:	60e2                	ld	ra,24(sp)
    800053c4:	6442                	ld	s0,16(sp)
    800053c6:	6105                	addi	sp,sp,32
    800053c8:	8082                	ret

00000000800053ca <sys_fstat>:
{
    800053ca:	1101                	addi	sp,sp,-32
    800053cc:	ec06                	sd	ra,24(sp)
    800053ce:	e822                	sd	s0,16(sp)
    800053d0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d2:	fe840613          	addi	a2,s0,-24
    800053d6:	4581                	li	a1,0
    800053d8:	4501                	li	a0,0
    800053da:	00000097          	auipc	ra,0x0
    800053de:	c76080e7          	jalr	-906(ra) # 80005050 <argfd>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e4:	02054563          	bltz	a0,8000540e <sys_fstat+0x44>
    800053e8:	fe040593          	addi	a1,s0,-32
    800053ec:	4505                	li	a0,1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	858080e7          	jalr	-1960(ra) # 80002c46 <argaddr>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053f8:	00054b63          	bltz	a0,8000540e <sys_fstat+0x44>
  return filestat(f, st);
    800053fc:	fe043583          	ld	a1,-32(s0)
    80005400:	fe843503          	ld	a0,-24(s0)
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	32a080e7          	jalr	810(ra) # 8000472e <filestat>
    8000540c:	87aa                	mv	a5,a0
}
    8000540e:	853e                	mv	a0,a5
    80005410:	60e2                	ld	ra,24(sp)
    80005412:	6442                	ld	s0,16(sp)
    80005414:	6105                	addi	sp,sp,32
    80005416:	8082                	ret

0000000080005418 <sys_link>:
{
    80005418:	7169                	addi	sp,sp,-304
    8000541a:	f606                	sd	ra,296(sp)
    8000541c:	f222                	sd	s0,288(sp)
    8000541e:	ee26                	sd	s1,280(sp)
    80005420:	ea4a                	sd	s2,272(sp)
    80005422:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005424:	08000613          	li	a2,128
    80005428:	ed040593          	addi	a1,s0,-304
    8000542c:	4501                	li	a0,0
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	83a080e7          	jalr	-1990(ra) # 80002c68 <argstr>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005438:	10054e63          	bltz	a0,80005554 <sys_link+0x13c>
    8000543c:	08000613          	li	a2,128
    80005440:	f5040593          	addi	a1,s0,-176
    80005444:	4505                	li	a0,1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	822080e7          	jalr	-2014(ra) # 80002c68 <argstr>
    return -1;
    8000544e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005450:	10054263          	bltz	a0,80005554 <sys_link+0x13c>
  begin_op();
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	d46080e7          	jalr	-698(ra) # 8000419a <begin_op>
  if((ip = namei(old)) == 0){
    8000545c:	ed040513          	addi	a0,s0,-304
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	b1e080e7          	jalr	-1250(ra) # 80003f7e <namei>
    80005468:	84aa                	mv	s1,a0
    8000546a:	c551                	beqz	a0,800054f6 <sys_link+0xde>
  ilock(ip);
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	35c080e7          	jalr	860(ra) # 800037c8 <ilock>
  if(ip->type == T_DIR){
    80005474:	04449703          	lh	a4,68(s1)
    80005478:	4785                	li	a5,1
    8000547a:	08f70463          	beq	a4,a5,80005502 <sys_link+0xea>
  ip->nlink++;
    8000547e:	04a4d783          	lhu	a5,74(s1)
    80005482:	2785                	addiw	a5,a5,1
    80005484:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	274080e7          	jalr	628(ra) # 800036fe <iupdate>
  iunlock(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	3f6080e7          	jalr	1014(ra) # 8000388a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000549c:	fd040593          	addi	a1,s0,-48
    800054a0:	f5040513          	addi	a0,s0,-176
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	af8080e7          	jalr	-1288(ra) # 80003f9c <nameiparent>
    800054ac:	892a                	mv	s2,a0
    800054ae:	c935                	beqz	a0,80005522 <sys_link+0x10a>
  ilock(dp);
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	318080e7          	jalr	792(ra) # 800037c8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054b8:	00092703          	lw	a4,0(s2)
    800054bc:	409c                	lw	a5,0(s1)
    800054be:	04f71d63          	bne	a4,a5,80005518 <sys_link+0x100>
    800054c2:	40d0                	lw	a2,4(s1)
    800054c4:	fd040593          	addi	a1,s0,-48
    800054c8:	854a                	mv	a0,s2
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	9f2080e7          	jalr	-1550(ra) # 80003ebc <dirlink>
    800054d2:	04054363          	bltz	a0,80005518 <sys_link+0x100>
  iunlockput(dp);
    800054d6:	854a                	mv	a0,s2
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	552080e7          	jalr	1362(ra) # 80003a2a <iunlockput>
  iput(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	4a0080e7          	jalr	1184(ra) # 80003982 <iput>
  end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	d30080e7          	jalr	-720(ra) # 8000421a <end_op>
  return 0;
    800054f2:	4781                	li	a5,0
    800054f4:	a085                	j	80005554 <sys_link+0x13c>
    end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	d24080e7          	jalr	-732(ra) # 8000421a <end_op>
    return -1;
    800054fe:	57fd                	li	a5,-1
    80005500:	a891                	j	80005554 <sys_link+0x13c>
    iunlockput(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	526080e7          	jalr	1318(ra) # 80003a2a <iunlockput>
    end_op();
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	d0e080e7          	jalr	-754(ra) # 8000421a <end_op>
    return -1;
    80005514:	57fd                	li	a5,-1
    80005516:	a83d                	j	80005554 <sys_link+0x13c>
    iunlockput(dp);
    80005518:	854a                	mv	a0,s2
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	510080e7          	jalr	1296(ra) # 80003a2a <iunlockput>
  ilock(ip);
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	2a4080e7          	jalr	676(ra) # 800037c8 <ilock>
  ip->nlink--;
    8000552c:	04a4d783          	lhu	a5,74(s1)
    80005530:	37fd                	addiw	a5,a5,-1
    80005532:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	1c6080e7          	jalr	454(ra) # 800036fe <iupdate>
  iunlockput(ip);
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	4e8080e7          	jalr	1256(ra) # 80003a2a <iunlockput>
  end_op();
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	cd0080e7          	jalr	-816(ra) # 8000421a <end_op>
  return -1;
    80005552:	57fd                	li	a5,-1
}
    80005554:	853e                	mv	a0,a5
    80005556:	70b2                	ld	ra,296(sp)
    80005558:	7412                	ld	s0,288(sp)
    8000555a:	64f2                	ld	s1,280(sp)
    8000555c:	6952                	ld	s2,272(sp)
    8000555e:	6155                	addi	sp,sp,304
    80005560:	8082                	ret

0000000080005562 <sys_unlink>:
{
    80005562:	7151                	addi	sp,sp,-240
    80005564:	f586                	sd	ra,232(sp)
    80005566:	f1a2                	sd	s0,224(sp)
    80005568:	eda6                	sd	s1,216(sp)
    8000556a:	e9ca                	sd	s2,208(sp)
    8000556c:	e5ce                	sd	s3,200(sp)
    8000556e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005570:	08000613          	li	a2,128
    80005574:	f3040593          	addi	a1,s0,-208
    80005578:	4501                	li	a0,0
    8000557a:	ffffd097          	auipc	ra,0xffffd
    8000557e:	6ee080e7          	jalr	1774(ra) # 80002c68 <argstr>
    80005582:	18054163          	bltz	a0,80005704 <sys_unlink+0x1a2>
  begin_op();
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	c14080e7          	jalr	-1004(ra) # 8000419a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000558e:	fb040593          	addi	a1,s0,-80
    80005592:	f3040513          	addi	a0,s0,-208
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	a06080e7          	jalr	-1530(ra) # 80003f9c <nameiparent>
    8000559e:	84aa                	mv	s1,a0
    800055a0:	c979                	beqz	a0,80005676 <sys_unlink+0x114>
  ilock(dp);
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	226080e7          	jalr	550(ra) # 800037c8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055aa:	00003597          	auipc	a1,0x3
    800055ae:	13e58593          	addi	a1,a1,318 # 800086e8 <syscalls+0x2b8>
    800055b2:	fb040513          	addi	a0,s0,-80
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	6dc080e7          	jalr	1756(ra) # 80003c92 <namecmp>
    800055be:	14050a63          	beqz	a0,80005712 <sys_unlink+0x1b0>
    800055c2:	00003597          	auipc	a1,0x3
    800055c6:	12e58593          	addi	a1,a1,302 # 800086f0 <syscalls+0x2c0>
    800055ca:	fb040513          	addi	a0,s0,-80
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	6c4080e7          	jalr	1732(ra) # 80003c92 <namecmp>
    800055d6:	12050e63          	beqz	a0,80005712 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055da:	f2c40613          	addi	a2,s0,-212
    800055de:	fb040593          	addi	a1,s0,-80
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	6c8080e7          	jalr	1736(ra) # 80003cac <dirlookup>
    800055ec:	892a                	mv	s2,a0
    800055ee:	12050263          	beqz	a0,80005712 <sys_unlink+0x1b0>
  ilock(ip);
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	1d6080e7          	jalr	470(ra) # 800037c8 <ilock>
  if(ip->nlink < 1)
    800055fa:	04a91783          	lh	a5,74(s2)
    800055fe:	08f05263          	blez	a5,80005682 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005602:	04491703          	lh	a4,68(s2)
    80005606:	4785                	li	a5,1
    80005608:	08f70563          	beq	a4,a5,80005692 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000560c:	4641                	li	a2,16
    8000560e:	4581                	li	a1,0
    80005610:	fc040513          	addi	a0,s0,-64
    80005614:	ffffb097          	auipc	ra,0xffffb
    80005618:	6be080e7          	jalr	1726(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000561c:	4741                	li	a4,16
    8000561e:	f2c42683          	lw	a3,-212(s0)
    80005622:	fc040613          	addi	a2,s0,-64
    80005626:	4581                	li	a1,0
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	54a080e7          	jalr	1354(ra) # 80003b74 <writei>
    80005632:	47c1                	li	a5,16
    80005634:	0af51563          	bne	a0,a5,800056de <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005638:	04491703          	lh	a4,68(s2)
    8000563c:	4785                	li	a5,1
    8000563e:	0af70863          	beq	a4,a5,800056ee <sys_unlink+0x18c>
  iunlockput(dp);
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	3e6080e7          	jalr	998(ra) # 80003a2a <iunlockput>
  ip->nlink--;
    8000564c:	04a95783          	lhu	a5,74(s2)
    80005650:	37fd                	addiw	a5,a5,-1
    80005652:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	0a6080e7          	jalr	166(ra) # 800036fe <iupdate>
  iunlockput(ip);
    80005660:	854a                	mv	a0,s2
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	3c8080e7          	jalr	968(ra) # 80003a2a <iunlockput>
  end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	bb0080e7          	jalr	-1104(ra) # 8000421a <end_op>
  return 0;
    80005672:	4501                	li	a0,0
    80005674:	a84d                	j	80005726 <sys_unlink+0x1c4>
    end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	ba4080e7          	jalr	-1116(ra) # 8000421a <end_op>
    return -1;
    8000567e:	557d                	li	a0,-1
    80005680:	a05d                	j	80005726 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005682:	00003517          	auipc	a0,0x3
    80005686:	09650513          	addi	a0,a0,150 # 80008718 <syscalls+0x2e8>
    8000568a:	ffffb097          	auipc	ra,0xffffb
    8000568e:	ea6080e7          	jalr	-346(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005692:	04c92703          	lw	a4,76(s2)
    80005696:	02000793          	li	a5,32
    8000569a:	f6e7f9e3          	bgeu	a5,a4,8000560c <sys_unlink+0xaa>
    8000569e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056a2:	4741                	li	a4,16
    800056a4:	86ce                	mv	a3,s3
    800056a6:	f1840613          	addi	a2,s0,-232
    800056aa:	4581                	li	a1,0
    800056ac:	854a                	mv	a0,s2
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	3ce080e7          	jalr	974(ra) # 80003a7c <readi>
    800056b6:	47c1                	li	a5,16
    800056b8:	00f51b63          	bne	a0,a5,800056ce <sys_unlink+0x16c>
    if(de.inum != 0)
    800056bc:	f1845783          	lhu	a5,-232(s0)
    800056c0:	e7a1                	bnez	a5,80005708 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c2:	29c1                	addiw	s3,s3,16
    800056c4:	04c92783          	lw	a5,76(s2)
    800056c8:	fcf9ede3          	bltu	s3,a5,800056a2 <sys_unlink+0x140>
    800056cc:	b781                	j	8000560c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ce:	00003517          	auipc	a0,0x3
    800056d2:	06250513          	addi	a0,a0,98 # 80008730 <syscalls+0x300>
    800056d6:	ffffb097          	auipc	ra,0xffffb
    800056da:	e5a080e7          	jalr	-422(ra) # 80000530 <panic>
    panic("unlink: writei");
    800056de:	00003517          	auipc	a0,0x3
    800056e2:	06a50513          	addi	a0,a0,106 # 80008748 <syscalls+0x318>
    800056e6:	ffffb097          	auipc	ra,0xffffb
    800056ea:	e4a080e7          	jalr	-438(ra) # 80000530 <panic>
    dp->nlink--;
    800056ee:	04a4d783          	lhu	a5,74(s1)
    800056f2:	37fd                	addiw	a5,a5,-1
    800056f4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	004080e7          	jalr	4(ra) # 800036fe <iupdate>
    80005702:	b781                	j	80005642 <sys_unlink+0xe0>
    return -1;
    80005704:	557d                	li	a0,-1
    80005706:	a005                	j	80005726 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	320080e7          	jalr	800(ra) # 80003a2a <iunlockput>
  iunlockput(dp);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	316080e7          	jalr	790(ra) # 80003a2a <iunlockput>
  end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	afe080e7          	jalr	-1282(ra) # 8000421a <end_op>
  return -1;
    80005724:	557d                	li	a0,-1
}
    80005726:	70ae                	ld	ra,232(sp)
    80005728:	740e                	ld	s0,224(sp)
    8000572a:	64ee                	ld	s1,216(sp)
    8000572c:	694e                	ld	s2,208(sp)
    8000572e:	69ae                	ld	s3,200(sp)
    80005730:	616d                	addi	sp,sp,240
    80005732:	8082                	ret

0000000080005734 <sys_open>:

uint64
sys_open(void)
{
    80005734:	7131                	addi	sp,sp,-192
    80005736:	fd06                	sd	ra,184(sp)
    80005738:	f922                	sd	s0,176(sp)
    8000573a:	f526                	sd	s1,168(sp)
    8000573c:	f14a                	sd	s2,160(sp)
    8000573e:	ed4e                	sd	s3,152(sp)
    80005740:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005742:	08000613          	li	a2,128
    80005746:	f5040593          	addi	a1,s0,-176
    8000574a:	4501                	li	a0,0
    8000574c:	ffffd097          	auipc	ra,0xffffd
    80005750:	51c080e7          	jalr	1308(ra) # 80002c68 <argstr>
    return -1;
    80005754:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005756:	0c054163          	bltz	a0,80005818 <sys_open+0xe4>
    8000575a:	f4c40593          	addi	a1,s0,-180
    8000575e:	4505                	li	a0,1
    80005760:	ffffd097          	auipc	ra,0xffffd
    80005764:	4c4080e7          	jalr	1220(ra) # 80002c24 <argint>
    80005768:	0a054863          	bltz	a0,80005818 <sys_open+0xe4>

  begin_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	a2e080e7          	jalr	-1490(ra) # 8000419a <begin_op>

  if(omode & O_CREATE){
    80005774:	f4c42783          	lw	a5,-180(s0)
    80005778:	2007f793          	andi	a5,a5,512
    8000577c:	cbdd                	beqz	a5,80005832 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000577e:	4681                	li	a3,0
    80005780:	4601                	li	a2,0
    80005782:	4589                	li	a1,2
    80005784:	f5040513          	addi	a0,s0,-176
    80005788:	00000097          	auipc	ra,0x0
    8000578c:	972080e7          	jalr	-1678(ra) # 800050fa <create>
    80005790:	892a                	mv	s2,a0
    if(ip == 0){
    80005792:	c959                	beqz	a0,80005828 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005794:	04491703          	lh	a4,68(s2)
    80005798:	478d                	li	a5,3
    8000579a:	00f71763          	bne	a4,a5,800057a8 <sys_open+0x74>
    8000579e:	04695703          	lhu	a4,70(s2)
    800057a2:	47a5                	li	a5,9
    800057a4:	0ce7ec63          	bltu	a5,a4,8000587c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	e02080e7          	jalr	-510(ra) # 800045aa <filealloc>
    800057b0:	89aa                	mv	s3,a0
    800057b2:	10050263          	beqz	a0,800058b6 <sys_open+0x182>
    800057b6:	00000097          	auipc	ra,0x0
    800057ba:	902080e7          	jalr	-1790(ra) # 800050b8 <fdalloc>
    800057be:	84aa                	mv	s1,a0
    800057c0:	0e054663          	bltz	a0,800058ac <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057c4:	04491703          	lh	a4,68(s2)
    800057c8:	478d                	li	a5,3
    800057ca:	0cf70463          	beq	a4,a5,80005892 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ce:	4789                	li	a5,2
    800057d0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057d4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057d8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057dc:	f4c42783          	lw	a5,-180(s0)
    800057e0:	0017c713          	xori	a4,a5,1
    800057e4:	8b05                	andi	a4,a4,1
    800057e6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ea:	0037f713          	andi	a4,a5,3
    800057ee:	00e03733          	snez	a4,a4
    800057f2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057f6:	4007f793          	andi	a5,a5,1024
    800057fa:	c791                	beqz	a5,80005806 <sys_open+0xd2>
    800057fc:	04491703          	lh	a4,68(s2)
    80005800:	4789                	li	a5,2
    80005802:	08f70f63          	beq	a4,a5,800058a0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005806:	854a                	mv	a0,s2
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	082080e7          	jalr	130(ra) # 8000388a <iunlock>
  end_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	a0a080e7          	jalr	-1526(ra) # 8000421a <end_op>

  return fd;
}
    80005818:	8526                	mv	a0,s1
    8000581a:	70ea                	ld	ra,184(sp)
    8000581c:	744a                	ld	s0,176(sp)
    8000581e:	74aa                	ld	s1,168(sp)
    80005820:	790a                	ld	s2,160(sp)
    80005822:	69ea                	ld	s3,152(sp)
    80005824:	6129                	addi	sp,sp,192
    80005826:	8082                	ret
      end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	9f2080e7          	jalr	-1550(ra) # 8000421a <end_op>
      return -1;
    80005830:	b7e5                	j	80005818 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005832:	f5040513          	addi	a0,s0,-176
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	748080e7          	jalr	1864(ra) # 80003f7e <namei>
    8000583e:	892a                	mv	s2,a0
    80005840:	c905                	beqz	a0,80005870 <sys_open+0x13c>
    ilock(ip);
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	f86080e7          	jalr	-122(ra) # 800037c8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000584a:	04491703          	lh	a4,68(s2)
    8000584e:	4785                	li	a5,1
    80005850:	f4f712e3          	bne	a4,a5,80005794 <sys_open+0x60>
    80005854:	f4c42783          	lw	a5,-180(s0)
    80005858:	dba1                	beqz	a5,800057a8 <sys_open+0x74>
      iunlockput(ip);
    8000585a:	854a                	mv	a0,s2
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	1ce080e7          	jalr	462(ra) # 80003a2a <iunlockput>
      end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	9b6080e7          	jalr	-1610(ra) # 8000421a <end_op>
      return -1;
    8000586c:	54fd                	li	s1,-1
    8000586e:	b76d                	j	80005818 <sys_open+0xe4>
      end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	9aa080e7          	jalr	-1622(ra) # 8000421a <end_op>
      return -1;
    80005878:	54fd                	li	s1,-1
    8000587a:	bf79                	j	80005818 <sys_open+0xe4>
    iunlockput(ip);
    8000587c:	854a                	mv	a0,s2
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	1ac080e7          	jalr	428(ra) # 80003a2a <iunlockput>
    end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	994080e7          	jalr	-1644(ra) # 8000421a <end_op>
    return -1;
    8000588e:	54fd                	li	s1,-1
    80005890:	b761                	j	80005818 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005892:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005896:	04691783          	lh	a5,70(s2)
    8000589a:	02f99223          	sh	a5,36(s3)
    8000589e:	bf2d                	j	800057d8 <sys_open+0xa4>
    itrunc(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	034080e7          	jalr	52(ra) # 800038d6 <itrunc>
    800058aa:	bfb1                	j	80005806 <sys_open+0xd2>
      fileclose(f);
    800058ac:	854e                	mv	a0,s3
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	db8080e7          	jalr	-584(ra) # 80004666 <fileclose>
    iunlockput(ip);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	172080e7          	jalr	370(ra) # 80003a2a <iunlockput>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	95a080e7          	jalr	-1702(ra) # 8000421a <end_op>
    return -1;
    800058c8:	54fd                	li	s1,-1
    800058ca:	b7b9                	j	80005818 <sys_open+0xe4>

00000000800058cc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058cc:	7175                	addi	sp,sp,-144
    800058ce:	e506                	sd	ra,136(sp)
    800058d0:	e122                	sd	s0,128(sp)
    800058d2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	8c6080e7          	jalr	-1850(ra) # 8000419a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058dc:	08000613          	li	a2,128
    800058e0:	f7040593          	addi	a1,s0,-144
    800058e4:	4501                	li	a0,0
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	382080e7          	jalr	898(ra) # 80002c68 <argstr>
    800058ee:	02054963          	bltz	a0,80005920 <sys_mkdir+0x54>
    800058f2:	4681                	li	a3,0
    800058f4:	4601                	li	a2,0
    800058f6:	4585                	li	a1,1
    800058f8:	f7040513          	addi	a0,s0,-144
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	7fe080e7          	jalr	2046(ra) # 800050fa <create>
    80005904:	cd11                	beqz	a0,80005920 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	124080e7          	jalr	292(ra) # 80003a2a <iunlockput>
  end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	90c080e7          	jalr	-1780(ra) # 8000421a <end_op>
  return 0;
    80005916:	4501                	li	a0,0
}
    80005918:	60aa                	ld	ra,136(sp)
    8000591a:	640a                	ld	s0,128(sp)
    8000591c:	6149                	addi	sp,sp,144
    8000591e:	8082                	ret
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	8fa080e7          	jalr	-1798(ra) # 8000421a <end_op>
    return -1;
    80005928:	557d                	li	a0,-1
    8000592a:	b7fd                	j	80005918 <sys_mkdir+0x4c>

000000008000592c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000592c:	7135                	addi	sp,sp,-160
    8000592e:	ed06                	sd	ra,152(sp)
    80005930:	e922                	sd	s0,144(sp)
    80005932:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	866080e7          	jalr	-1946(ra) # 8000419a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000593c:	08000613          	li	a2,128
    80005940:	f7040593          	addi	a1,s0,-144
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	322080e7          	jalr	802(ra) # 80002c68 <argstr>
    8000594e:	04054a63          	bltz	a0,800059a2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005952:	f6c40593          	addi	a1,s0,-148
    80005956:	4505                	li	a0,1
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	2cc080e7          	jalr	716(ra) # 80002c24 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005960:	04054163          	bltz	a0,800059a2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005964:	f6840593          	addi	a1,s0,-152
    80005968:	4509                	li	a0,2
    8000596a:	ffffd097          	auipc	ra,0xffffd
    8000596e:	2ba080e7          	jalr	698(ra) # 80002c24 <argint>
     argint(1, &major) < 0 ||
    80005972:	02054863          	bltz	a0,800059a2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005976:	f6841683          	lh	a3,-152(s0)
    8000597a:	f6c41603          	lh	a2,-148(s0)
    8000597e:	458d                	li	a1,3
    80005980:	f7040513          	addi	a0,s0,-144
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	776080e7          	jalr	1910(ra) # 800050fa <create>
     argint(2, &minor) < 0 ||
    8000598c:	c919                	beqz	a0,800059a2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	09c080e7          	jalr	156(ra) # 80003a2a <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	884080e7          	jalr	-1916(ra) # 8000421a <end_op>
  return 0;
    8000599e:	4501                	li	a0,0
    800059a0:	a031                	j	800059ac <sys_mknod+0x80>
    end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	878080e7          	jalr	-1928(ra) # 8000421a <end_op>
    return -1;
    800059aa:	557d                	li	a0,-1
}
    800059ac:	60ea                	ld	ra,152(sp)
    800059ae:	644a                	ld	s0,144(sp)
    800059b0:	610d                	addi	sp,sp,160
    800059b2:	8082                	ret

00000000800059b4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059b4:	7135                	addi	sp,sp,-160
    800059b6:	ed06                	sd	ra,152(sp)
    800059b8:	e922                	sd	s0,144(sp)
    800059ba:	e526                	sd	s1,136(sp)
    800059bc:	e14a                	sd	s2,128(sp)
    800059be:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c0:	ffffc097          	auipc	ra,0xffffc
    800059c4:	fd4080e7          	jalr	-44(ra) # 80001994 <myproc>
    800059c8:	892a                	mv	s2,a0
  
  begin_op();
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	7d0080e7          	jalr	2000(ra) # 8000419a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d2:	08000613          	li	a2,128
    800059d6:	f6040593          	addi	a1,s0,-160
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	28c080e7          	jalr	652(ra) # 80002c68 <argstr>
    800059e4:	04054b63          	bltz	a0,80005a3a <sys_chdir+0x86>
    800059e8:	f6040513          	addi	a0,s0,-160
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	592080e7          	jalr	1426(ra) # 80003f7e <namei>
    800059f4:	84aa                	mv	s1,a0
    800059f6:	c131                	beqz	a0,80005a3a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	dd0080e7          	jalr	-560(ra) # 800037c8 <ilock>
  if(ip->type != T_DIR){
    80005a00:	04449703          	lh	a4,68(s1)
    80005a04:	4785                	li	a5,1
    80005a06:	04f71063          	bne	a4,a5,80005a46 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	e7e080e7          	jalr	-386(ra) # 8000388a <iunlock>
  iput(p->cwd);
    80005a14:	15093503          	ld	a0,336(s2)
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	f6a080e7          	jalr	-150(ra) # 80003982 <iput>
  end_op();
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	7fa080e7          	jalr	2042(ra) # 8000421a <end_op>
  p->cwd = ip;
    80005a28:	14993823          	sd	s1,336(s2)
  return 0;
    80005a2c:	4501                	li	a0,0
}
    80005a2e:	60ea                	ld	ra,152(sp)
    80005a30:	644a                	ld	s0,144(sp)
    80005a32:	64aa                	ld	s1,136(sp)
    80005a34:	690a                	ld	s2,128(sp)
    80005a36:	610d                	addi	sp,sp,160
    80005a38:	8082                	ret
    end_op();
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	7e0080e7          	jalr	2016(ra) # 8000421a <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	b7ed                	j	80005a2e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	fe2080e7          	jalr	-30(ra) # 80003a2a <iunlockput>
    end_op();
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	7ca080e7          	jalr	1994(ra) # 8000421a <end_op>
    return -1;
    80005a58:	557d                	li	a0,-1
    80005a5a:	bfd1                	j	80005a2e <sys_chdir+0x7a>

0000000080005a5c <sys_exec>:

uint64
sys_exec(void)
{
    80005a5c:	7145                	addi	sp,sp,-464
    80005a5e:	e786                	sd	ra,456(sp)
    80005a60:	e3a2                	sd	s0,448(sp)
    80005a62:	ff26                	sd	s1,440(sp)
    80005a64:	fb4a                	sd	s2,432(sp)
    80005a66:	f74e                	sd	s3,424(sp)
    80005a68:	f352                	sd	s4,416(sp)
    80005a6a:	ef56                	sd	s5,408(sp)
    80005a6c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a6e:	08000613          	li	a2,128
    80005a72:	f4040593          	addi	a1,s0,-192
    80005a76:	4501                	li	a0,0
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	1f0080e7          	jalr	496(ra) # 80002c68 <argstr>
    return -1;
    80005a80:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a82:	0c054a63          	bltz	a0,80005b56 <sys_exec+0xfa>
    80005a86:	e3840593          	addi	a1,s0,-456
    80005a8a:	4505                	li	a0,1
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	1ba080e7          	jalr	442(ra) # 80002c46 <argaddr>
    80005a94:	0c054163          	bltz	a0,80005b56 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a98:	10000613          	li	a2,256
    80005a9c:	4581                	li	a1,0
    80005a9e:	e4040513          	addi	a0,s0,-448
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	230080e7          	jalr	560(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aaa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aae:	89a6                	mv	s3,s1
    80005ab0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab2:	02000a13          	li	s4,32
    80005ab6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aba:	00391513          	slli	a0,s2,0x3
    80005abe:	e3040593          	addi	a1,s0,-464
    80005ac2:	e3843783          	ld	a5,-456(s0)
    80005ac6:	953e                	add	a0,a0,a5
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	0c2080e7          	jalr	194(ra) # 80002b8a <fetchaddr>
    80005ad0:	02054a63          	bltz	a0,80005b04 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ad4:	e3043783          	ld	a5,-464(s0)
    80005ad8:	c3b9                	beqz	a5,80005b1e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	00c080e7          	jalr	12(ra) # 80000ae6 <kalloc>
    80005ae2:	85aa                	mv	a1,a0
    80005ae4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ae8:	cd11                	beqz	a0,80005b04 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aea:	6605                	lui	a2,0x1
    80005aec:	e3043503          	ld	a0,-464(s0)
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	0ec080e7          	jalr	236(ra) # 80002bdc <fetchstr>
    80005af8:	00054663          	bltz	a0,80005b04 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005afc:	0905                	addi	s2,s2,1
    80005afe:	09a1                	addi	s3,s3,8
    80005b00:	fb491be3          	bne	s2,s4,80005ab6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b04:	10048913          	addi	s2,s1,256
    80005b08:	6088                	ld	a0,0(s1)
    80005b0a:	c529                	beqz	a0,80005b54 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b0c:	ffffb097          	auipc	ra,0xffffb
    80005b10:	ede080e7          	jalr	-290(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b14:	04a1                	addi	s1,s1,8
    80005b16:	ff2499e3          	bne	s1,s2,80005b08 <sys_exec+0xac>
  return -1;
    80005b1a:	597d                	li	s2,-1
    80005b1c:	a82d                	j	80005b56 <sys_exec+0xfa>
      argv[i] = 0;
    80005b1e:	0a8e                	slli	s5,s5,0x3
    80005b20:	fc040793          	addi	a5,s0,-64
    80005b24:	9abe                	add	s5,s5,a5
    80005b26:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2a:	e4040593          	addi	a1,s0,-448
    80005b2e:	f4040513          	addi	a0,s0,-192
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	194080e7          	jalr	404(ra) # 80004cc6 <exec>
    80005b3a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3c:	10048993          	addi	s3,s1,256
    80005b40:	6088                	ld	a0,0(s1)
    80005b42:	c911                	beqz	a0,80005b56 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b44:	ffffb097          	auipc	ra,0xffffb
    80005b48:	ea6080e7          	jalr	-346(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4c:	04a1                	addi	s1,s1,8
    80005b4e:	ff3499e3          	bne	s1,s3,80005b40 <sys_exec+0xe4>
    80005b52:	a011                	j	80005b56 <sys_exec+0xfa>
  return -1;
    80005b54:	597d                	li	s2,-1
}
    80005b56:	854a                	mv	a0,s2
    80005b58:	60be                	ld	ra,456(sp)
    80005b5a:	641e                	ld	s0,448(sp)
    80005b5c:	74fa                	ld	s1,440(sp)
    80005b5e:	795a                	ld	s2,432(sp)
    80005b60:	79ba                	ld	s3,424(sp)
    80005b62:	7a1a                	ld	s4,416(sp)
    80005b64:	6afa                	ld	s5,408(sp)
    80005b66:	6179                	addi	sp,sp,464
    80005b68:	8082                	ret

0000000080005b6a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6a:	7139                	addi	sp,sp,-64
    80005b6c:	fc06                	sd	ra,56(sp)
    80005b6e:	f822                	sd	s0,48(sp)
    80005b70:	f426                	sd	s1,40(sp)
    80005b72:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b74:	ffffc097          	auipc	ra,0xffffc
    80005b78:	e20080e7          	jalr	-480(ra) # 80001994 <myproc>
    80005b7c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b7e:	fd840593          	addi	a1,s0,-40
    80005b82:	4501                	li	a0,0
    80005b84:	ffffd097          	auipc	ra,0xffffd
    80005b88:	0c2080e7          	jalr	194(ra) # 80002c46 <argaddr>
    return -1;
    80005b8c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b8e:	0e054063          	bltz	a0,80005c6e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b92:	fc840593          	addi	a1,s0,-56
    80005b96:	fd040513          	addi	a0,s0,-48
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	dfc080e7          	jalr	-516(ra) # 80004996 <pipealloc>
    return -1;
    80005ba2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ba4:	0c054563          	bltz	a0,80005c6e <sys_pipe+0x104>
  fd0 = -1;
    80005ba8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bac:	fd043503          	ld	a0,-48(s0)
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	508080e7          	jalr	1288(ra) # 800050b8 <fdalloc>
    80005bb8:	fca42223          	sw	a0,-60(s0)
    80005bbc:	08054c63          	bltz	a0,80005c54 <sys_pipe+0xea>
    80005bc0:	fc843503          	ld	a0,-56(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	4f4080e7          	jalr	1268(ra) # 800050b8 <fdalloc>
    80005bcc:	fca42023          	sw	a0,-64(s0)
    80005bd0:	06054863          	bltz	a0,80005c40 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd4:	4691                	li	a3,4
    80005bd6:	fc440613          	addi	a2,s0,-60
    80005bda:	fd843583          	ld	a1,-40(s0)
    80005bde:	68a8                	ld	a0,80(s1)
    80005be0:	ffffc097          	auipc	ra,0xffffc
    80005be4:	a76080e7          	jalr	-1418(ra) # 80001656 <copyout>
    80005be8:	02054063          	bltz	a0,80005c08 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bec:	4691                	li	a3,4
    80005bee:	fc040613          	addi	a2,s0,-64
    80005bf2:	fd843583          	ld	a1,-40(s0)
    80005bf6:	0591                	addi	a1,a1,4
    80005bf8:	68a8                	ld	a0,80(s1)
    80005bfa:	ffffc097          	auipc	ra,0xffffc
    80005bfe:	a5c080e7          	jalr	-1444(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c02:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c04:	06055563          	bgez	a0,80005c6e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c08:	fc442783          	lw	a5,-60(s0)
    80005c0c:	07e9                	addi	a5,a5,26
    80005c0e:	078e                	slli	a5,a5,0x3
    80005c10:	97a6                	add	a5,a5,s1
    80005c12:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c16:	fc042503          	lw	a0,-64(s0)
    80005c1a:	0569                	addi	a0,a0,26
    80005c1c:	050e                	slli	a0,a0,0x3
    80005c1e:	9526                	add	a0,a0,s1
    80005c20:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c24:	fd043503          	ld	a0,-48(s0)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	a3e080e7          	jalr	-1474(ra) # 80004666 <fileclose>
    fileclose(wf);
    80005c30:	fc843503          	ld	a0,-56(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	a32080e7          	jalr	-1486(ra) # 80004666 <fileclose>
    return -1;
    80005c3c:	57fd                	li	a5,-1
    80005c3e:	a805                	j	80005c6e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c40:	fc442783          	lw	a5,-60(s0)
    80005c44:	0007c863          	bltz	a5,80005c54 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c48:	01a78513          	addi	a0,a5,26
    80005c4c:	050e                	slli	a0,a0,0x3
    80005c4e:	9526                	add	a0,a0,s1
    80005c50:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c54:	fd043503          	ld	a0,-48(s0)
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	a0e080e7          	jalr	-1522(ra) # 80004666 <fileclose>
    fileclose(wf);
    80005c60:	fc843503          	ld	a0,-56(s0)
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	a02080e7          	jalr	-1534(ra) # 80004666 <fileclose>
    return -1;
    80005c6c:	57fd                	li	a5,-1
}
    80005c6e:	853e                	mv	a0,a5
    80005c70:	70e2                	ld	ra,56(sp)
    80005c72:	7442                	ld	s0,48(sp)
    80005c74:	74a2                	ld	s1,40(sp)
    80005c76:	6121                	addi	sp,sp,64
    80005c78:	8082                	ret
    80005c7a:	0000                	unimp
    80005c7c:	0000                	unimp
	...

0000000080005c80 <kernelvec>:
    80005c80:	7111                	addi	sp,sp,-256
    80005c82:	e006                	sd	ra,0(sp)
    80005c84:	e40a                	sd	sp,8(sp)
    80005c86:	e80e                	sd	gp,16(sp)
    80005c88:	ec12                	sd	tp,24(sp)
    80005c8a:	f016                	sd	t0,32(sp)
    80005c8c:	f41a                	sd	t1,40(sp)
    80005c8e:	f81e                	sd	t2,48(sp)
    80005c90:	fc22                	sd	s0,56(sp)
    80005c92:	e0a6                	sd	s1,64(sp)
    80005c94:	e4aa                	sd	a0,72(sp)
    80005c96:	e8ae                	sd	a1,80(sp)
    80005c98:	ecb2                	sd	a2,88(sp)
    80005c9a:	f0b6                	sd	a3,96(sp)
    80005c9c:	f4ba                	sd	a4,104(sp)
    80005c9e:	f8be                	sd	a5,112(sp)
    80005ca0:	fcc2                	sd	a6,120(sp)
    80005ca2:	e146                	sd	a7,128(sp)
    80005ca4:	e54a                	sd	s2,136(sp)
    80005ca6:	e94e                	sd	s3,144(sp)
    80005ca8:	ed52                	sd	s4,152(sp)
    80005caa:	f156                	sd	s5,160(sp)
    80005cac:	f55a                	sd	s6,168(sp)
    80005cae:	f95e                	sd	s7,176(sp)
    80005cb0:	fd62                	sd	s8,184(sp)
    80005cb2:	e1e6                	sd	s9,192(sp)
    80005cb4:	e5ea                	sd	s10,200(sp)
    80005cb6:	e9ee                	sd	s11,208(sp)
    80005cb8:	edf2                	sd	t3,216(sp)
    80005cba:	f1f6                	sd	t4,224(sp)
    80005cbc:	f5fa                	sd	t5,232(sp)
    80005cbe:	f9fe                	sd	t6,240(sp)
    80005cc0:	d97fc0ef          	jal	ra,80002a56 <kerneltrap>
    80005cc4:	6082                	ld	ra,0(sp)
    80005cc6:	6122                	ld	sp,8(sp)
    80005cc8:	61c2                	ld	gp,16(sp)
    80005cca:	7282                	ld	t0,32(sp)
    80005ccc:	7322                	ld	t1,40(sp)
    80005cce:	73c2                	ld	t2,48(sp)
    80005cd0:	7462                	ld	s0,56(sp)
    80005cd2:	6486                	ld	s1,64(sp)
    80005cd4:	6526                	ld	a0,72(sp)
    80005cd6:	65c6                	ld	a1,80(sp)
    80005cd8:	6666                	ld	a2,88(sp)
    80005cda:	7686                	ld	a3,96(sp)
    80005cdc:	7726                	ld	a4,104(sp)
    80005cde:	77c6                	ld	a5,112(sp)
    80005ce0:	7866                	ld	a6,120(sp)
    80005ce2:	688a                	ld	a7,128(sp)
    80005ce4:	692a                	ld	s2,136(sp)
    80005ce6:	69ca                	ld	s3,144(sp)
    80005ce8:	6a6a                	ld	s4,152(sp)
    80005cea:	7a8a                	ld	s5,160(sp)
    80005cec:	7b2a                	ld	s6,168(sp)
    80005cee:	7bca                	ld	s7,176(sp)
    80005cf0:	7c6a                	ld	s8,184(sp)
    80005cf2:	6c8e                	ld	s9,192(sp)
    80005cf4:	6d2e                	ld	s10,200(sp)
    80005cf6:	6dce                	ld	s11,208(sp)
    80005cf8:	6e6e                	ld	t3,216(sp)
    80005cfa:	7e8e                	ld	t4,224(sp)
    80005cfc:	7f2e                	ld	t5,232(sp)
    80005cfe:	7fce                	ld	t6,240(sp)
    80005d00:	6111                	addi	sp,sp,256
    80005d02:	10200073          	sret
    80005d06:	00000013          	nop
    80005d0a:	00000013          	nop
    80005d0e:	0001                	nop

0000000080005d10 <timervec>:
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	e10c                	sd	a1,0(a0)
    80005d16:	e510                	sd	a2,8(a0)
    80005d18:	e914                	sd	a3,16(a0)
    80005d1a:	6d0c                	ld	a1,24(a0)
    80005d1c:	7110                	ld	a2,32(a0)
    80005d1e:	6194                	ld	a3,0(a1)
    80005d20:	96b2                	add	a3,a3,a2
    80005d22:	e194                	sd	a3,0(a1)
    80005d24:	4589                	li	a1,2
    80005d26:	14459073          	csrw	sip,a1
    80005d2a:	6914                	ld	a3,16(a0)
    80005d2c:	6510                	ld	a2,8(a0)
    80005d2e:	610c                	ld	a1,0(a0)
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	30200073          	mret
	...

0000000080005d3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d3a:	1141                	addi	sp,sp,-16
    80005d3c:	e422                	sd	s0,8(sp)
    80005d3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d40:	0c0007b7          	lui	a5,0xc000
    80005d44:	4705                	li	a4,1
    80005d46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d48:	c3d8                	sw	a4,4(a5)
}
    80005d4a:	6422                	ld	s0,8(sp)
    80005d4c:	0141                	addi	sp,sp,16
    80005d4e:	8082                	ret

0000000080005d50 <plicinithart>:

void
plicinithart(void)
{
    80005d50:	1141                	addi	sp,sp,-16
    80005d52:	e406                	sd	ra,8(sp)
    80005d54:	e022                	sd	s0,0(sp)
    80005d56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	c10080e7          	jalr	-1008(ra) # 80001968 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d60:	0085171b          	slliw	a4,a0,0x8
    80005d64:	0c0027b7          	lui	a5,0xc002
    80005d68:	97ba                	add	a5,a5,a4
    80005d6a:	40200713          	li	a4,1026
    80005d6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d72:	00d5151b          	slliw	a0,a0,0xd
    80005d76:	0c2017b7          	lui	a5,0xc201
    80005d7a:	953e                	add	a0,a0,a5
    80005d7c:	00052023          	sw	zero,0(a0)
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret

0000000080005d88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d88:	1141                	addi	sp,sp,-16
    80005d8a:	e406                	sd	ra,8(sp)
    80005d8c:	e022                	sd	s0,0(sp)
    80005d8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	bd8080e7          	jalr	-1064(ra) # 80001968 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d98:	00d5179b          	slliw	a5,a0,0xd
    80005d9c:	0c201537          	lui	a0,0xc201
    80005da0:	953e                	add	a0,a0,a5
  return irq;
}
    80005da2:	4148                	lw	a0,4(a0)
    80005da4:	60a2                	ld	ra,8(sp)
    80005da6:	6402                	ld	s0,0(sp)
    80005da8:	0141                	addi	sp,sp,16
    80005daa:	8082                	ret

0000000080005dac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dac:	1101                	addi	sp,sp,-32
    80005dae:	ec06                	sd	ra,24(sp)
    80005db0:	e822                	sd	s0,16(sp)
    80005db2:	e426                	sd	s1,8(sp)
    80005db4:	1000                	addi	s0,sp,32
    80005db6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	bb0080e7          	jalr	-1104(ra) # 80001968 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dc0:	00d5151b          	slliw	a0,a0,0xd
    80005dc4:	0c2017b7          	lui	a5,0xc201
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	c3c4                	sw	s1,4(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret

0000000080005dd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dd6:	1141                	addi	sp,sp,-16
    80005dd8:	e406                	sd	ra,8(sp)
    80005dda:	e022                	sd	s0,0(sp)
    80005ddc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dde:	479d                	li	a5,7
    80005de0:	06a7c963          	blt	a5,a0,80005e52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005de4:	0001d797          	auipc	a5,0x1d
    80005de8:	21c78793          	addi	a5,a5,540 # 80023000 <disk>
    80005dec:	00a78733          	add	a4,a5,a0
    80005df0:	6789                	lui	a5,0x2
    80005df2:	97ba                	add	a5,a5,a4
    80005df4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005df8:	e7ad                	bnez	a5,80005e62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dfa:	00451793          	slli	a5,a0,0x4
    80005dfe:	0001f717          	auipc	a4,0x1f
    80005e02:	20270713          	addi	a4,a4,514 # 80025000 <disk+0x2000>
    80005e06:	6314                	ld	a3,0(a4)
    80005e08:	96be                	add	a3,a3,a5
    80005e0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e0e:	6314                	ld	a3,0(a4)
    80005e10:	96be                	add	a3,a3,a5
    80005e12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e16:	6314                	ld	a3,0(a4)
    80005e18:	96be                	add	a3,a3,a5
    80005e1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e1e:	6318                	ld	a4,0(a4)
    80005e20:	97ba                	add	a5,a5,a4
    80005e22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e26:	0001d797          	auipc	a5,0x1d
    80005e2a:	1da78793          	addi	a5,a5,474 # 80023000 <disk>
    80005e2e:	97aa                	add	a5,a5,a0
    80005e30:	6509                	lui	a0,0x2
    80005e32:	953e                	add	a0,a0,a5
    80005e34:	4785                	li	a5,1
    80005e36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e3a:	0001f517          	auipc	a0,0x1f
    80005e3e:	1de50513          	addi	a0,a0,478 # 80025018 <disk+0x2018>
    80005e42:	ffffc097          	auipc	ra,0xffffc
    80005e46:	406080e7          	jalr	1030(ra) # 80002248 <wakeup>
}
    80005e4a:	60a2                	ld	ra,8(sp)
    80005e4c:	6402                	ld	s0,0(sp)
    80005e4e:	0141                	addi	sp,sp,16
    80005e50:	8082                	ret
    panic("free_desc 1");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	90650513          	addi	a0,a0,-1786 # 80008758 <syscalls+0x328>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6d6080e7          	jalr	1750(ra) # 80000530 <panic>
    panic("free_desc 2");
    80005e62:	00003517          	auipc	a0,0x3
    80005e66:	90650513          	addi	a0,a0,-1786 # 80008768 <syscalls+0x338>
    80005e6a:	ffffa097          	auipc	ra,0xffffa
    80005e6e:	6c6080e7          	jalr	1734(ra) # 80000530 <panic>

0000000080005e72 <virtio_disk_init>:
{
    80005e72:	1101                	addi	sp,sp,-32
    80005e74:	ec06                	sd	ra,24(sp)
    80005e76:	e822                	sd	s0,16(sp)
    80005e78:	e426                	sd	s1,8(sp)
    80005e7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e7c:	00003597          	auipc	a1,0x3
    80005e80:	8fc58593          	addi	a1,a1,-1796 # 80008778 <syscalls+0x348>
    80005e84:	0001f517          	auipc	a0,0x1f
    80005e88:	2a450513          	addi	a0,a0,676 # 80025128 <disk+0x2128>
    80005e8c:	ffffb097          	auipc	ra,0xffffb
    80005e90:	cba080e7          	jalr	-838(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e94:	100017b7          	lui	a5,0x10001
    80005e98:	4398                	lw	a4,0(a5)
    80005e9a:	2701                	sext.w	a4,a4
    80005e9c:	747277b7          	lui	a5,0x74727
    80005ea0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ea4:	0ef71163          	bne	a4,a5,80005f86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ea8:	100017b7          	lui	a5,0x10001
    80005eac:	43dc                	lw	a5,4(a5)
    80005eae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb0:	4705                	li	a4,1
    80005eb2:	0ce79a63          	bne	a5,a4,80005f86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eb6:	100017b7          	lui	a5,0x10001
    80005eba:	479c                	lw	a5,8(a5)
    80005ebc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ebe:	4709                	li	a4,2
    80005ec0:	0ce79363          	bne	a5,a4,80005f86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ec4:	100017b7          	lui	a5,0x10001
    80005ec8:	47d8                	lw	a4,12(a5)
    80005eca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ecc:	554d47b7          	lui	a5,0x554d4
    80005ed0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ed4:	0af71963          	bne	a4,a5,80005f86 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	100017b7          	lui	a5,0x10001
    80005edc:	4705                	li	a4,1
    80005ede:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee0:	470d                	li	a4,3
    80005ee2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ee4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ee6:	c7ffe737          	lui	a4,0xc7ffe
    80005eea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005eee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ef0:	2701                	sext.w	a4,a4
    80005ef2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef4:	472d                	li	a4,11
    80005ef6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef8:	473d                	li	a4,15
    80005efa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005efc:	6705                	lui	a4,0x1
    80005efe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f04:	5bdc                	lw	a5,52(a5)
    80005f06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f08:	c7d9                	beqz	a5,80005f96 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f0a:	471d                	li	a4,7
    80005f0c:	08f77d63          	bgeu	a4,a5,80005fa6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f10:	100014b7          	lui	s1,0x10001
    80005f14:	47a1                	li	a5,8
    80005f16:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f18:	6609                	lui	a2,0x2
    80005f1a:	4581                	li	a1,0
    80005f1c:	0001d517          	auipc	a0,0x1d
    80005f20:	0e450513          	addi	a0,a0,228 # 80023000 <disk>
    80005f24:	ffffb097          	auipc	ra,0xffffb
    80005f28:	dae080e7          	jalr	-594(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f2c:	0001d717          	auipc	a4,0x1d
    80005f30:	0d470713          	addi	a4,a4,212 # 80023000 <disk>
    80005f34:	00c75793          	srli	a5,a4,0xc
    80005f38:	2781                	sext.w	a5,a5
    80005f3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f3c:	0001f797          	auipc	a5,0x1f
    80005f40:	0c478793          	addi	a5,a5,196 # 80025000 <disk+0x2000>
    80005f44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f46:	0001d717          	auipc	a4,0x1d
    80005f4a:	13a70713          	addi	a4,a4,314 # 80023080 <disk+0x80>
    80005f4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f50:	0001e717          	auipc	a4,0x1e
    80005f54:	0b070713          	addi	a4,a4,176 # 80024000 <disk+0x1000>
    80005f58:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f5a:	4705                	li	a4,1
    80005f5c:	00e78c23          	sb	a4,24(a5)
    80005f60:	00e78ca3          	sb	a4,25(a5)
    80005f64:	00e78d23          	sb	a4,26(a5)
    80005f68:	00e78da3          	sb	a4,27(a5)
    80005f6c:	00e78e23          	sb	a4,28(a5)
    80005f70:	00e78ea3          	sb	a4,29(a5)
    80005f74:	00e78f23          	sb	a4,30(a5)
    80005f78:	00e78fa3          	sb	a4,31(a5)
}
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	64a2                	ld	s1,8(sp)
    80005f82:	6105                	addi	sp,sp,32
    80005f84:	8082                	ret
    panic("could not find virtio disk");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	80250513          	addi	a0,a0,-2046 # 80008788 <syscalls+0x358>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5a2080e7          	jalr	1442(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80005f96:	00003517          	auipc	a0,0x3
    80005f9a:	81250513          	addi	a0,a0,-2030 # 800087a8 <syscalls+0x378>
    80005f9e:	ffffa097          	auipc	ra,0xffffa
    80005fa2:	592080e7          	jalr	1426(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80005fa6:	00003517          	auipc	a0,0x3
    80005faa:	82250513          	addi	a0,a0,-2014 # 800087c8 <syscalls+0x398>
    80005fae:	ffffa097          	auipc	ra,0xffffa
    80005fb2:	582080e7          	jalr	1410(ra) # 80000530 <panic>

0000000080005fb6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fb6:	7159                	addi	sp,sp,-112
    80005fb8:	f486                	sd	ra,104(sp)
    80005fba:	f0a2                	sd	s0,96(sp)
    80005fbc:	eca6                	sd	s1,88(sp)
    80005fbe:	e8ca                	sd	s2,80(sp)
    80005fc0:	e4ce                	sd	s3,72(sp)
    80005fc2:	e0d2                	sd	s4,64(sp)
    80005fc4:	fc56                	sd	s5,56(sp)
    80005fc6:	f85a                	sd	s6,48(sp)
    80005fc8:	f45e                	sd	s7,40(sp)
    80005fca:	f062                	sd	s8,32(sp)
    80005fcc:	ec66                	sd	s9,24(sp)
    80005fce:	e86a                	sd	s10,16(sp)
    80005fd0:	1880                	addi	s0,sp,112
    80005fd2:	892a                	mv	s2,a0
    80005fd4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fd6:	00c52c83          	lw	s9,12(a0)
    80005fda:	001c9c9b          	slliw	s9,s9,0x1
    80005fde:	1c82                	slli	s9,s9,0x20
    80005fe0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fe4:	0001f517          	auipc	a0,0x1f
    80005fe8:	14450513          	addi	a0,a0,324 # 80025128 <disk+0x2128>
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	bea080e7          	jalr	-1046(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005ff4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ff6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ff8:	0001db97          	auipc	s7,0x1d
    80005ffc:	008b8b93          	addi	s7,s7,8 # 80023000 <disk>
    80006000:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006002:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006004:	8a4e                	mv	s4,s3
    80006006:	a051                	j	8000608a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006008:	00fb86b3          	add	a3,s7,a5
    8000600c:	96da                	add	a3,a3,s6
    8000600e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006012:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006014:	0207c563          	bltz	a5,8000603e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006018:	2485                	addiw	s1,s1,1
    8000601a:	0711                	addi	a4,a4,4
    8000601c:	25548063          	beq	s1,s5,8000625c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006020:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006022:	0001f697          	auipc	a3,0x1f
    80006026:	ff668693          	addi	a3,a3,-10 # 80025018 <disk+0x2018>
    8000602a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000602c:	0006c583          	lbu	a1,0(a3)
    80006030:	fde1                	bnez	a1,80006008 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006032:	2785                	addiw	a5,a5,1
    80006034:	0685                	addi	a3,a3,1
    80006036:	ff879be3          	bne	a5,s8,8000602c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000603a:	57fd                	li	a5,-1
    8000603c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000603e:	02905a63          	blez	s1,80006072 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006042:	f9042503          	lw	a0,-112(s0)
    80006046:	00000097          	auipc	ra,0x0
    8000604a:	d90080e7          	jalr	-624(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    8000604e:	4785                	li	a5,1
    80006050:	0297d163          	bge	a5,s1,80006072 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006054:	f9442503          	lw	a0,-108(s0)
    80006058:	00000097          	auipc	ra,0x0
    8000605c:	d7e080e7          	jalr	-642(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006060:	4789                	li	a5,2
    80006062:	0097d863          	bge	a5,s1,80006072 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006066:	f9842503          	lw	a0,-104(s0)
    8000606a:	00000097          	auipc	ra,0x0
    8000606e:	d6c080e7          	jalr	-660(ra) # 80005dd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006072:	0001f597          	auipc	a1,0x1f
    80006076:	0b658593          	addi	a1,a1,182 # 80025128 <disk+0x2128>
    8000607a:	0001f517          	auipc	a0,0x1f
    8000607e:	f9e50513          	addi	a0,a0,-98 # 80025018 <disk+0x2018>
    80006082:	ffffc097          	auipc	ra,0xffffc
    80006086:	03a080e7          	jalr	58(ra) # 800020bc <sleep>
  for(int i = 0; i < 3; i++){
    8000608a:	f9040713          	addi	a4,s0,-112
    8000608e:	84ce                	mv	s1,s3
    80006090:	bf41                	j	80006020 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006092:	20058713          	addi	a4,a1,512
    80006096:	00471693          	slli	a3,a4,0x4
    8000609a:	0001d717          	auipc	a4,0x1d
    8000609e:	f6670713          	addi	a4,a4,-154 # 80023000 <disk>
    800060a2:	9736                	add	a4,a4,a3
    800060a4:	4685                	li	a3,1
    800060a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060aa:	20058713          	addi	a4,a1,512
    800060ae:	00471693          	slli	a3,a4,0x4
    800060b2:	0001d717          	auipc	a4,0x1d
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80023000 <disk>
    800060ba:	9736                	add	a4,a4,a3
    800060bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060c4:	7679                	lui	a2,0xffffe
    800060c6:	963e                	add	a2,a2,a5
    800060c8:	0001f697          	auipc	a3,0x1f
    800060cc:	f3868693          	addi	a3,a3,-200 # 80025000 <disk+0x2000>
    800060d0:	6298                	ld	a4,0(a3)
    800060d2:	9732                	add	a4,a4,a2
    800060d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060d6:	6298                	ld	a4,0(a3)
    800060d8:	9732                	add	a4,a4,a2
    800060da:	4541                	li	a0,16
    800060dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060de:	6298                	ld	a4,0(a3)
    800060e0:	9732                	add	a4,a4,a2
    800060e2:	4505                	li	a0,1
    800060e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060e8:	f9442703          	lw	a4,-108(s0)
    800060ec:	6288                	ld	a0,0(a3)
    800060ee:	962a                	add	a2,a2,a0
    800060f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060f4:	0712                	slli	a4,a4,0x4
    800060f6:	6290                	ld	a2,0(a3)
    800060f8:	963a                	add	a2,a2,a4
    800060fa:	05890513          	addi	a0,s2,88
    800060fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006100:	6294                	ld	a3,0(a3)
    80006102:	96ba                	add	a3,a3,a4
    80006104:	40000613          	li	a2,1024
    80006108:	c690                	sw	a2,8(a3)
  if(write)
    8000610a:	140d0063          	beqz	s10,8000624a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000610e:	0001f697          	auipc	a3,0x1f
    80006112:	ef26b683          	ld	a3,-270(a3) # 80025000 <disk+0x2000>
    80006116:	96ba                	add	a3,a3,a4
    80006118:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000611c:	0001d817          	auipc	a6,0x1d
    80006120:	ee480813          	addi	a6,a6,-284 # 80023000 <disk>
    80006124:	0001f517          	auipc	a0,0x1f
    80006128:	edc50513          	addi	a0,a0,-292 # 80025000 <disk+0x2000>
    8000612c:	6114                	ld	a3,0(a0)
    8000612e:	96ba                	add	a3,a3,a4
    80006130:	00c6d603          	lhu	a2,12(a3)
    80006134:	00166613          	ori	a2,a2,1
    80006138:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000613c:	f9842683          	lw	a3,-104(s0)
    80006140:	6110                	ld	a2,0(a0)
    80006142:	9732                	add	a4,a4,a2
    80006144:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006148:	20058613          	addi	a2,a1,512
    8000614c:	0612                	slli	a2,a2,0x4
    8000614e:	9642                	add	a2,a2,a6
    80006150:	577d                	li	a4,-1
    80006152:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006156:	00469713          	slli	a4,a3,0x4
    8000615a:	6114                	ld	a3,0(a0)
    8000615c:	96ba                	add	a3,a3,a4
    8000615e:	03078793          	addi	a5,a5,48
    80006162:	97c2                	add	a5,a5,a6
    80006164:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006166:	611c                	ld	a5,0(a0)
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	4685                	li	a3,1
    8000616c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000616e:	611c                	ld	a5,0(a0)
    80006170:	97ba                	add	a5,a5,a4
    80006172:	4809                	li	a6,2
    80006174:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006178:	611c                	ld	a5,0(a0)
    8000617a:	973e                	add	a4,a4,a5
    8000617c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006180:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006184:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006188:	6518                	ld	a4,8(a0)
    8000618a:	00275783          	lhu	a5,2(a4)
    8000618e:	8b9d                	andi	a5,a5,7
    80006190:	0786                	slli	a5,a5,0x1
    80006192:	97ba                	add	a5,a5,a4
    80006194:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006198:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000619c:	6518                	ld	a4,8(a0)
    8000619e:	00275783          	lhu	a5,2(a4)
    800061a2:	2785                	addiw	a5,a5,1
    800061a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061ac:	100017b7          	lui	a5,0x10001
    800061b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061b4:	00492703          	lw	a4,4(s2)
    800061b8:	4785                	li	a5,1
    800061ba:	02f71163          	bne	a4,a5,800061dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800061be:	0001f997          	auipc	s3,0x1f
    800061c2:	f6a98993          	addi	s3,s3,-150 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061c8:	85ce                	mv	a1,s3
    800061ca:	854a                	mv	a0,s2
    800061cc:	ffffc097          	auipc	ra,0xffffc
    800061d0:	ef0080e7          	jalr	-272(ra) # 800020bc <sleep>
  while(b->disk == 1) {
    800061d4:	00492783          	lw	a5,4(s2)
    800061d8:	fe9788e3          	beq	a5,s1,800061c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061dc:	f9042903          	lw	s2,-112(s0)
    800061e0:	20090793          	addi	a5,s2,512
    800061e4:	00479713          	slli	a4,a5,0x4
    800061e8:	0001d797          	auipc	a5,0x1d
    800061ec:	e1878793          	addi	a5,a5,-488 # 80023000 <disk>
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061f6:	0001f997          	auipc	s3,0x1f
    800061fa:	e0a98993          	addi	s3,s3,-502 # 80025000 <disk+0x2000>
    800061fe:	00491713          	slli	a4,s2,0x4
    80006202:	0009b783          	ld	a5,0(s3)
    80006206:	97ba                	add	a5,a5,a4
    80006208:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000620c:	854a                	mv	a0,s2
    8000620e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006212:	00000097          	auipc	ra,0x0
    80006216:	bc4080e7          	jalr	-1084(ra) # 80005dd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000621a:	8885                	andi	s1,s1,1
    8000621c:	f0ed                	bnez	s1,800061fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000621e:	0001f517          	auipc	a0,0x1f
    80006222:	f0a50513          	addi	a0,a0,-246 # 80025128 <disk+0x2128>
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	a64080e7          	jalr	-1436(ra) # 80000c8a <release>
}
    8000622e:	70a6                	ld	ra,104(sp)
    80006230:	7406                	ld	s0,96(sp)
    80006232:	64e6                	ld	s1,88(sp)
    80006234:	6946                	ld	s2,80(sp)
    80006236:	69a6                	ld	s3,72(sp)
    80006238:	6a06                	ld	s4,64(sp)
    8000623a:	7ae2                	ld	s5,56(sp)
    8000623c:	7b42                	ld	s6,48(sp)
    8000623e:	7ba2                	ld	s7,40(sp)
    80006240:	7c02                	ld	s8,32(sp)
    80006242:	6ce2                	ld	s9,24(sp)
    80006244:	6d42                	ld	s10,16(sp)
    80006246:	6165                	addi	sp,sp,112
    80006248:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000624a:	0001f697          	auipc	a3,0x1f
    8000624e:	db66b683          	ld	a3,-586(a3) # 80025000 <disk+0x2000>
    80006252:	96ba                	add	a3,a3,a4
    80006254:	4609                	li	a2,2
    80006256:	00c69623          	sh	a2,12(a3)
    8000625a:	b5c9                	j	8000611c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000625c:	f9042583          	lw	a1,-112(s0)
    80006260:	20058793          	addi	a5,a1,512
    80006264:	0792                	slli	a5,a5,0x4
    80006266:	0001d517          	auipc	a0,0x1d
    8000626a:	e4250513          	addi	a0,a0,-446 # 800230a8 <disk+0xa8>
    8000626e:	953e                	add	a0,a0,a5
  if(write)
    80006270:	e20d11e3          	bnez	s10,80006092 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006274:	20058713          	addi	a4,a1,512
    80006278:	00471693          	slli	a3,a4,0x4
    8000627c:	0001d717          	auipc	a4,0x1d
    80006280:	d8470713          	addi	a4,a4,-636 # 80023000 <disk>
    80006284:	9736                	add	a4,a4,a3
    80006286:	0a072423          	sw	zero,168(a4)
    8000628a:	b505                	j	800060aa <virtio_disk_rw+0xf4>

000000008000628c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000628c:	1101                	addi	sp,sp,-32
    8000628e:	ec06                	sd	ra,24(sp)
    80006290:	e822                	sd	s0,16(sp)
    80006292:	e426                	sd	s1,8(sp)
    80006294:	e04a                	sd	s2,0(sp)
    80006296:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006298:	0001f517          	auipc	a0,0x1f
    8000629c:	e9050513          	addi	a0,a0,-368 # 80025128 <disk+0x2128>
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062a8:	10001737          	lui	a4,0x10001
    800062ac:	533c                	lw	a5,96(a4)
    800062ae:	8b8d                	andi	a5,a5,3
    800062b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062b6:	0001f797          	auipc	a5,0x1f
    800062ba:	d4a78793          	addi	a5,a5,-694 # 80025000 <disk+0x2000>
    800062be:	6b94                	ld	a3,16(a5)
    800062c0:	0207d703          	lhu	a4,32(a5)
    800062c4:	0026d783          	lhu	a5,2(a3)
    800062c8:	06f70163          	beq	a4,a5,8000632a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062cc:	0001d917          	auipc	s2,0x1d
    800062d0:	d3490913          	addi	s2,s2,-716 # 80023000 <disk>
    800062d4:	0001f497          	auipc	s1,0x1f
    800062d8:	d2c48493          	addi	s1,s1,-724 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062e0:	6898                	ld	a4,16(s1)
    800062e2:	0204d783          	lhu	a5,32(s1)
    800062e6:	8b9d                	andi	a5,a5,7
    800062e8:	078e                	slli	a5,a5,0x3
    800062ea:	97ba                	add	a5,a5,a4
    800062ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062ee:	20078713          	addi	a4,a5,512
    800062f2:	0712                	slli	a4,a4,0x4
    800062f4:	974a                	add	a4,a4,s2
    800062f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062fa:	e731                	bnez	a4,80006346 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062fc:	20078793          	addi	a5,a5,512
    80006300:	0792                	slli	a5,a5,0x4
    80006302:	97ca                	add	a5,a5,s2
    80006304:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006306:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000630a:	ffffc097          	auipc	ra,0xffffc
    8000630e:	f3e080e7          	jalr	-194(ra) # 80002248 <wakeup>

    disk.used_idx += 1;
    80006312:	0204d783          	lhu	a5,32(s1)
    80006316:	2785                	addiw	a5,a5,1
    80006318:	17c2                	slli	a5,a5,0x30
    8000631a:	93c1                	srli	a5,a5,0x30
    8000631c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006320:	6898                	ld	a4,16(s1)
    80006322:	00275703          	lhu	a4,2(a4)
    80006326:	faf71be3          	bne	a4,a5,800062dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000632a:	0001f517          	auipc	a0,0x1f
    8000632e:	dfe50513          	addi	a0,a0,-514 # 80025128 <disk+0x2128>
    80006332:	ffffb097          	auipc	ra,0xffffb
    80006336:	958080e7          	jalr	-1704(ra) # 80000c8a <release>
}
    8000633a:	60e2                	ld	ra,24(sp)
    8000633c:	6442                	ld	s0,16(sp)
    8000633e:	64a2                	ld	s1,8(sp)
    80006340:	6902                	ld	s2,0(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret
      panic("virtio_disk_intr status");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	4a250513          	addi	a0,a0,1186 # 800087e8 <syscalls+0x3b8>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1e2080e7          	jalr	482(ra) # 80000530 <panic>
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
