
user/_uscheduler:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <process_init>:
struct process *current_process;
extern void context_switch(uint64, uint64);
              
void 
process_init(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  // main() is process 0, which will make the first invocation to
  // scheduler().  it needs a stack so that the first context_switch() can
  // save process 0's state.  scheduler() won't run the main process ever
  // again, because its state is set to RUNNING, and scheduler() selects
  // a RUNNABLE process.
}
   6:	6422                	ld	s0,8(sp)
   8:	0141                	addi	sp,sp,16
   a:	8082                	ret

000000000000000c <scheduler>:

void 
scheduler(void)
{
   c:	1141                	addi	sp,sp,-16
   e:	e422                	sd	s0,8(sp)
  10:	0800                	addi	s0,sp,16

}
  12:	6422                	ld	s0,8(sp)
  14:	0141                	addi	sp,sp,16
  16:	8082                	ret

0000000000000018 <sched>:

void 
sched(void (*func)())
{
  18:	1141                	addi	sp,sp,-16
  1a:	e422                	sd	s0,8(sp)
  1c:	0800                	addi	s0,sp,16

}
  1e:	6422                	ld	s0,8(sp)
  20:	0141                	addi	sp,sp,16
  22:	8082                	ret

0000000000000024 <yield>:

void 
yield(void)
{
  24:	1141                	addi	sp,sp,-16
  26:	e422                	sd	s0,8(sp)
  28:	0800                	addi	s0,sp,16

}
  2a:	6422                	ld	s0,8(sp)
  2c:	0141                	addi	sp,sp,16
  2e:	8082                	ret

0000000000000030 <process_a>:
volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
process_a(void)
{
  30:	7179                	addi	sp,sp,-48
  32:	f406                	sd	ra,40(sp)
  34:	f022                	sd	s0,32(sp)
  36:	ec26                	sd	s1,24(sp)
  38:	e84a                	sd	s2,16(sp)
  3a:	e44e                	sd	s3,8(sp)
  3c:	e052                	sd	s4,0(sp)
  3e:	1800                	addi	s0,sp,48
  int i;
  printf("process_a started\n");
  40:	00001517          	auipc	a0,0x1
  44:	9e050513          	addi	a0,a0,-1568 # a20 <malloc+0xea>
  48:	00001097          	auipc	ra,0x1
  4c:	830080e7          	jalr	-2000(ra) # 878 <printf>
  a_started = 1;
  50:	4785                	li	a5,1
  52:	00001717          	auipc	a4,0x1
  56:	acf72d23          	sw	a5,-1318(a4) # b2c <a_started>
  while(b_started == 0 || c_started == 0)
  5a:	00001717          	auipc	a4,0x1
  5e:	ace70713          	addi	a4,a4,-1330 # b28 <b_started>
  62:	00001697          	auipc	a3,0x1
  66:	ac268693          	addi	a3,a3,-1342 # b24 <c_started>
  6a:	431c                	lw	a5,0(a4)
  6c:	2781                	sext.w	a5,a5
  6e:	dff5                	beqz	a5,6a <process_a+0x3a>
  70:	429c                	lw	a5,0(a3)
  72:	2781                	sext.w	a5,a5
  74:	dbfd                	beqz	a5,6a <process_a+0x3a>
    yield();
  
  for (i = 0; i < 100; i++) {
  76:	4481                	li	s1,0
    printf("process_a %d\n", i);
  78:	00001a17          	auipc	s4,0x1
  7c:	9c0a0a13          	addi	s4,s4,-1600 # a38 <malloc+0x102>
    a_n += 1;
  80:	00001917          	auipc	s2,0x1
  84:	aa090913          	addi	s2,s2,-1376 # b20 <a_n>
  for (i = 0; i < 100; i++) {
  88:	06400993          	li	s3,100
    printf("process_a %d\n", i);
  8c:	85a6                	mv	a1,s1
  8e:	8552                	mv	a0,s4
  90:	00000097          	auipc	ra,0x0
  94:	7e8080e7          	jalr	2024(ra) # 878 <printf>
    a_n += 1;
  98:	00092783          	lw	a5,0(s2)
  9c:	2785                	addiw	a5,a5,1
  9e:	00f92023          	sw	a5,0(s2)
  for (i = 0; i < 100; i++) {
  a2:	2485                	addiw	s1,s1,1
  a4:	ff3494e3          	bne	s1,s3,8c <process_a+0x5c>
    yield();
  }
  printf("process_a: exit after %d\n", a_n);
  a8:	00001597          	auipc	a1,0x1
  ac:	a785a583          	lw	a1,-1416(a1) # b20 <a_n>
  b0:	00001517          	auipc	a0,0x1
  b4:	99850513          	addi	a0,a0,-1640 # a48 <malloc+0x112>
  b8:	00000097          	auipc	ra,0x0
  bc:	7c0080e7          	jalr	1984(ra) # 878 <printf>

  current_process->state = FREE;
  c0:	00001797          	auipc	a5,0x1
  c4:	a707b783          	ld	a5,-1424(a5) # b30 <current_process>
  c8:	6709                	lui	a4,0x2
  ca:	97ba                	add	a5,a5,a4
  cc:	0607a823          	sw	zero,112(a5)
  scheduler();
}
  d0:	70a2                	ld	ra,40(sp)
  d2:	7402                	ld	s0,32(sp)
  d4:	64e2                	ld	s1,24(sp)
  d6:	6942                	ld	s2,16(sp)
  d8:	69a2                	ld	s3,8(sp)
  da:	6a02                	ld	s4,0(sp)
  dc:	6145                	addi	sp,sp,48
  de:	8082                	ret

00000000000000e0 <process_b>:

void 
process_b(void)
{
  e0:	7179                	addi	sp,sp,-48
  e2:	f406                	sd	ra,40(sp)
  e4:	f022                	sd	s0,32(sp)
  e6:	ec26                	sd	s1,24(sp)
  e8:	e84a                	sd	s2,16(sp)
  ea:	e44e                	sd	s3,8(sp)
  ec:	e052                	sd	s4,0(sp)
  ee:	1800                	addi	s0,sp,48
  int i;
  printf("process_b started\n");
  f0:	00001517          	auipc	a0,0x1
  f4:	97850513          	addi	a0,a0,-1672 # a68 <malloc+0x132>
  f8:	00000097          	auipc	ra,0x0
  fc:	780080e7          	jalr	1920(ra) # 878 <printf>
  b_started = 1;
 100:	4785                	li	a5,1
 102:	00001717          	auipc	a4,0x1
 106:	a2f72323          	sw	a5,-1498(a4) # b28 <b_started>
  while(a_started == 0 || c_started == 0)
 10a:	00001717          	auipc	a4,0x1
 10e:	a2270713          	addi	a4,a4,-1502 # b2c <a_started>
 112:	00001697          	auipc	a3,0x1
 116:	a1268693          	addi	a3,a3,-1518 # b24 <c_started>
 11a:	431c                	lw	a5,0(a4)
 11c:	2781                	sext.w	a5,a5
 11e:	dff5                	beqz	a5,11a <process_b+0x3a>
 120:	429c                	lw	a5,0(a3)
 122:	2781                	sext.w	a5,a5
 124:	dbfd                	beqz	a5,11a <process_b+0x3a>
    yield();
  
  for (i = 0; i < 100; i++) {
 126:	4481                	li	s1,0
    printf("process_b %d\n", i);
 128:	00001a17          	auipc	s4,0x1
 12c:	958a0a13          	addi	s4,s4,-1704 # a80 <malloc+0x14a>
    b_n += 1;
 130:	00001917          	auipc	s2,0x1
 134:	9ec90913          	addi	s2,s2,-1556 # b1c <b_n>
  for (i = 0; i < 100; i++) {
 138:	06400993          	li	s3,100
    printf("process_b %d\n", i);
 13c:	85a6                	mv	a1,s1
 13e:	8552                	mv	a0,s4
 140:	00000097          	auipc	ra,0x0
 144:	738080e7          	jalr	1848(ra) # 878 <printf>
    b_n += 1;
 148:	00092783          	lw	a5,0(s2)
 14c:	2785                	addiw	a5,a5,1
 14e:	00f92023          	sw	a5,0(s2)
  for (i = 0; i < 100; i++) {
 152:	2485                	addiw	s1,s1,1
 154:	ff3494e3          	bne	s1,s3,13c <process_b+0x5c>
    yield();
  }
  printf("process_b: exit after %d\n", b_n);
 158:	00001597          	auipc	a1,0x1
 15c:	9c45a583          	lw	a1,-1596(a1) # b1c <b_n>
 160:	00001517          	auipc	a0,0x1
 164:	93050513          	addi	a0,a0,-1744 # a90 <malloc+0x15a>
 168:	00000097          	auipc	ra,0x0
 16c:	710080e7          	jalr	1808(ra) # 878 <printf>

  current_process->state = FREE;
 170:	00001797          	auipc	a5,0x1
 174:	9c07b783          	ld	a5,-1600(a5) # b30 <current_process>
 178:	6709                	lui	a4,0x2
 17a:	97ba                	add	a5,a5,a4
 17c:	0607a823          	sw	zero,112(a5)
  scheduler();
}
 180:	70a2                	ld	ra,40(sp)
 182:	7402                	ld	s0,32(sp)
 184:	64e2                	ld	s1,24(sp)
 186:	6942                	ld	s2,16(sp)
 188:	69a2                	ld	s3,8(sp)
 18a:	6a02                	ld	s4,0(sp)
 18c:	6145                	addi	sp,sp,48
 18e:	8082                	ret

0000000000000190 <process_c>:

void 
process_c(void)
{
 190:	7179                	addi	sp,sp,-48
 192:	f406                	sd	ra,40(sp)
 194:	f022                	sd	s0,32(sp)
 196:	ec26                	sd	s1,24(sp)
 198:	e84a                	sd	s2,16(sp)
 19a:	e44e                	sd	s3,8(sp)
 19c:	e052                	sd	s4,0(sp)
 19e:	1800                	addi	s0,sp,48
  int i;
  printf("process_c started\n");
 1a0:	00001517          	auipc	a0,0x1
 1a4:	91050513          	addi	a0,a0,-1776 # ab0 <malloc+0x17a>
 1a8:	00000097          	auipc	ra,0x0
 1ac:	6d0080e7          	jalr	1744(ra) # 878 <printf>
  c_started = 1;
 1b0:	4785                	li	a5,1
 1b2:	00001717          	auipc	a4,0x1
 1b6:	96f72923          	sw	a5,-1678(a4) # b24 <c_started>
  while(a_started == 0 || b_started == 0)
 1ba:	00001717          	auipc	a4,0x1
 1be:	97270713          	addi	a4,a4,-1678 # b2c <a_started>
 1c2:	00001697          	auipc	a3,0x1
 1c6:	96668693          	addi	a3,a3,-1690 # b28 <b_started>
 1ca:	431c                	lw	a5,0(a4)
 1cc:	2781                	sext.w	a5,a5
 1ce:	dff5                	beqz	a5,1ca <process_c+0x3a>
 1d0:	429c                	lw	a5,0(a3)
 1d2:	2781                	sext.w	a5,a5
 1d4:	dbfd                	beqz	a5,1ca <process_c+0x3a>
    yield();
  
  for (i = 0; i < 100; i++) {
 1d6:	4481                	li	s1,0
    printf("process_c %d\n", i);
 1d8:	00001a17          	auipc	s4,0x1
 1dc:	8f0a0a13          	addi	s4,s4,-1808 # ac8 <malloc+0x192>
    c_n += 1;
 1e0:	00001917          	auipc	s2,0x1
 1e4:	93890913          	addi	s2,s2,-1736 # b18 <c_n>
  for (i = 0; i < 100; i++) {
 1e8:	06400993          	li	s3,100
    printf("process_c %d\n", i);
 1ec:	85a6                	mv	a1,s1
 1ee:	8552                	mv	a0,s4
 1f0:	00000097          	auipc	ra,0x0
 1f4:	688080e7          	jalr	1672(ra) # 878 <printf>
    c_n += 1;
 1f8:	00092783          	lw	a5,0(s2)
 1fc:	2785                	addiw	a5,a5,1
 1fe:	00f92023          	sw	a5,0(s2)
  for (i = 0; i < 100; i++) {
 202:	2485                	addiw	s1,s1,1
 204:	ff3494e3          	bne	s1,s3,1ec <process_c+0x5c>
    yield();
  }
  printf("process_c: exit after %d\n", c_n);
 208:	00001597          	auipc	a1,0x1
 20c:	9105a583          	lw	a1,-1776(a1) # b18 <c_n>
 210:	00001517          	auipc	a0,0x1
 214:	8c850513          	addi	a0,a0,-1848 # ad8 <malloc+0x1a2>
 218:	00000097          	auipc	ra,0x0
 21c:	660080e7          	jalr	1632(ra) # 878 <printf>

  current_process->state = FREE;
 220:	00001797          	auipc	a5,0x1
 224:	9107b783          	ld	a5,-1776(a5) # b30 <current_process>
 228:	6709                	lui	a4,0x2
 22a:	97ba                	add	a5,a5,a4
 22c:	0607a823          	sw	zero,112(a5)
  scheduler();
}
 230:	70a2                	ld	ra,40(sp)
 232:	7402                	ld	s0,32(sp)
 234:	64e2                	ld	s1,24(sp)
 236:	6942                	ld	s2,16(sp)
 238:	69a2                	ld	s3,8(sp)
 23a:	6a02                	ld	s4,0(sp)
 23c:	6145                	addi	sp,sp,48
 23e:	8082                	ret

0000000000000240 <main>:

int 
main(int argc, char *argv[]) 
{
 240:	1141                	addi	sp,sp,-16
 242:	e406                	sd	ra,8(sp)
 244:	e022                	sd	s0,0(sp)
 246:	0800                	addi	s0,sp,16
  a_started = b_started = c_started = 0;
 248:	00001797          	auipc	a5,0x1
 24c:	8c07ae23          	sw	zero,-1828(a5) # b24 <c_started>
 250:	00001797          	auipc	a5,0x1
 254:	8c07ac23          	sw	zero,-1832(a5) # b28 <b_started>
 258:	00001797          	auipc	a5,0x1
 25c:	8c07aa23          	sw	zero,-1836(a5) # b2c <a_started>
  a_n = b_n = c_n = 0;
 260:	00001797          	auipc	a5,0x1
 264:	8a07ac23          	sw	zero,-1864(a5) # b18 <c_n>
 268:	00001797          	auipc	a5,0x1
 26c:	8a07aa23          	sw	zero,-1868(a5) # b1c <b_n>
 270:	00001797          	auipc	a5,0x1
 274:	8a07a823          	sw	zero,-1872(a5) # b20 <a_n>
  process_init();
  sched(process_a);
  sched(process_b);
  sched(process_c);
  scheduler();
  exit(0);
 278:	4501                	li	a0,0
 27a:	00000097          	auipc	ra,0x0
 27e:	27e080e7          	jalr	638(ra) # 4f8 <exit>

0000000000000282 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 282:	1141                	addi	sp,sp,-16
 284:	e422                	sd	s0,8(sp)
 286:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 288:	87aa                	mv	a5,a0
 28a:	0585                	addi	a1,a1,1
 28c:	0785                	addi	a5,a5,1
 28e:	fff5c703          	lbu	a4,-1(a1)
 292:	fee78fa3          	sb	a4,-1(a5)
 296:	fb75                	bnez	a4,28a <strcpy+0x8>
    ;
  return os;
}
 298:	6422                	ld	s0,8(sp)
 29a:	0141                	addi	sp,sp,16
 29c:	8082                	ret

000000000000029e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 29e:	1141                	addi	sp,sp,-16
 2a0:	e422                	sd	s0,8(sp)
 2a2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2a4:	00054783          	lbu	a5,0(a0)
 2a8:	cb91                	beqz	a5,2bc <strcmp+0x1e>
 2aa:	0005c703          	lbu	a4,0(a1)
 2ae:	00f71763          	bne	a4,a5,2bc <strcmp+0x1e>
    p++, q++;
 2b2:	0505                	addi	a0,a0,1
 2b4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2b6:	00054783          	lbu	a5,0(a0)
 2ba:	fbe5                	bnez	a5,2aa <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2bc:	0005c503          	lbu	a0,0(a1)
}
 2c0:	40a7853b          	subw	a0,a5,a0
 2c4:	6422                	ld	s0,8(sp)
 2c6:	0141                	addi	sp,sp,16
 2c8:	8082                	ret

00000000000002ca <strlen>:

uint
strlen(const char *s)
{
 2ca:	1141                	addi	sp,sp,-16
 2cc:	e422                	sd	s0,8(sp)
 2ce:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2d0:	00054783          	lbu	a5,0(a0)
 2d4:	cf91                	beqz	a5,2f0 <strlen+0x26>
 2d6:	0505                	addi	a0,a0,1
 2d8:	87aa                	mv	a5,a0
 2da:	4685                	li	a3,1
 2dc:	9e89                	subw	a3,a3,a0
 2de:	00f6853b          	addw	a0,a3,a5
 2e2:	0785                	addi	a5,a5,1
 2e4:	fff7c703          	lbu	a4,-1(a5)
 2e8:	fb7d                	bnez	a4,2de <strlen+0x14>
    ;
  return n;
}
 2ea:	6422                	ld	s0,8(sp)
 2ec:	0141                	addi	sp,sp,16
 2ee:	8082                	ret
  for(n = 0; s[n]; n++)
 2f0:	4501                	li	a0,0
 2f2:	bfe5                	j	2ea <strlen+0x20>

00000000000002f4 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2f4:	1141                	addi	sp,sp,-16
 2f6:	e422                	sd	s0,8(sp)
 2f8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2fa:	ce09                	beqz	a2,314 <memset+0x20>
 2fc:	87aa                	mv	a5,a0
 2fe:	fff6071b          	addiw	a4,a2,-1
 302:	1702                	slli	a4,a4,0x20
 304:	9301                	srli	a4,a4,0x20
 306:	0705                	addi	a4,a4,1
 308:	972a                	add	a4,a4,a0
    cdst[i] = c;
 30a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 30e:	0785                	addi	a5,a5,1
 310:	fee79de3          	bne	a5,a4,30a <memset+0x16>
  }
  return dst;
}
 314:	6422                	ld	s0,8(sp)
 316:	0141                	addi	sp,sp,16
 318:	8082                	ret

000000000000031a <strchr>:

char*
strchr(const char *s, char c)
{
 31a:	1141                	addi	sp,sp,-16
 31c:	e422                	sd	s0,8(sp)
 31e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 320:	00054783          	lbu	a5,0(a0)
 324:	cb99                	beqz	a5,33a <strchr+0x20>
    if(*s == c)
 326:	00f58763          	beq	a1,a5,334 <strchr+0x1a>
  for(; *s; s++)
 32a:	0505                	addi	a0,a0,1
 32c:	00054783          	lbu	a5,0(a0)
 330:	fbfd                	bnez	a5,326 <strchr+0xc>
      return (char*)s;
  return 0;
 332:	4501                	li	a0,0
}
 334:	6422                	ld	s0,8(sp)
 336:	0141                	addi	sp,sp,16
 338:	8082                	ret
  return 0;
 33a:	4501                	li	a0,0
 33c:	bfe5                	j	334 <strchr+0x1a>

000000000000033e <gets>:

char*
gets(char *buf, int max)
{
 33e:	711d                	addi	sp,sp,-96
 340:	ec86                	sd	ra,88(sp)
 342:	e8a2                	sd	s0,80(sp)
 344:	e4a6                	sd	s1,72(sp)
 346:	e0ca                	sd	s2,64(sp)
 348:	fc4e                	sd	s3,56(sp)
 34a:	f852                	sd	s4,48(sp)
 34c:	f456                	sd	s5,40(sp)
 34e:	f05a                	sd	s6,32(sp)
 350:	ec5e                	sd	s7,24(sp)
 352:	1080                	addi	s0,sp,96
 354:	8baa                	mv	s7,a0
 356:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 358:	892a                	mv	s2,a0
 35a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 35c:	4aa9                	li	s5,10
 35e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 360:	89a6                	mv	s3,s1
 362:	2485                	addiw	s1,s1,1
 364:	0344d863          	bge	s1,s4,394 <gets+0x56>
    cc = read(0, &c, 1);
 368:	4605                	li	a2,1
 36a:	faf40593          	addi	a1,s0,-81
 36e:	4501                	li	a0,0
 370:	00000097          	auipc	ra,0x0
 374:	1a0080e7          	jalr	416(ra) # 510 <read>
    if(cc < 1)
 378:	00a05e63          	blez	a0,394 <gets+0x56>
    buf[i++] = c;
 37c:	faf44783          	lbu	a5,-81(s0)
 380:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 384:	01578763          	beq	a5,s5,392 <gets+0x54>
 388:	0905                	addi	s2,s2,1
 38a:	fd679be3          	bne	a5,s6,360 <gets+0x22>
  for(i=0; i+1 < max; ){
 38e:	89a6                	mv	s3,s1
 390:	a011                	j	394 <gets+0x56>
 392:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 394:	99de                	add	s3,s3,s7
 396:	00098023          	sb	zero,0(s3)
  return buf;
}
 39a:	855e                	mv	a0,s7
 39c:	60e6                	ld	ra,88(sp)
 39e:	6446                	ld	s0,80(sp)
 3a0:	64a6                	ld	s1,72(sp)
 3a2:	6906                	ld	s2,64(sp)
 3a4:	79e2                	ld	s3,56(sp)
 3a6:	7a42                	ld	s4,48(sp)
 3a8:	7aa2                	ld	s5,40(sp)
 3aa:	7b02                	ld	s6,32(sp)
 3ac:	6be2                	ld	s7,24(sp)
 3ae:	6125                	addi	sp,sp,96
 3b0:	8082                	ret

00000000000003b2 <stat>:

int
stat(const char *n, struct stat *st)
{
 3b2:	1101                	addi	sp,sp,-32
 3b4:	ec06                	sd	ra,24(sp)
 3b6:	e822                	sd	s0,16(sp)
 3b8:	e426                	sd	s1,8(sp)
 3ba:	e04a                	sd	s2,0(sp)
 3bc:	1000                	addi	s0,sp,32
 3be:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3c0:	4581                	li	a1,0
 3c2:	00000097          	auipc	ra,0x0
 3c6:	176080e7          	jalr	374(ra) # 538 <open>
  if(fd < 0)
 3ca:	02054563          	bltz	a0,3f4 <stat+0x42>
 3ce:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3d0:	85ca                	mv	a1,s2
 3d2:	00000097          	auipc	ra,0x0
 3d6:	17e080e7          	jalr	382(ra) # 550 <fstat>
 3da:	892a                	mv	s2,a0
  close(fd);
 3dc:	8526                	mv	a0,s1
 3de:	00000097          	auipc	ra,0x0
 3e2:	142080e7          	jalr	322(ra) # 520 <close>
  return r;
}
 3e6:	854a                	mv	a0,s2
 3e8:	60e2                	ld	ra,24(sp)
 3ea:	6442                	ld	s0,16(sp)
 3ec:	64a2                	ld	s1,8(sp)
 3ee:	6902                	ld	s2,0(sp)
 3f0:	6105                	addi	sp,sp,32
 3f2:	8082                	ret
    return -1;
 3f4:	597d                	li	s2,-1
 3f6:	bfc5                	j	3e6 <stat+0x34>

00000000000003f8 <atoi>:

int
atoi(const char *s)
{
 3f8:	1141                	addi	sp,sp,-16
 3fa:	e422                	sd	s0,8(sp)
 3fc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3fe:	00054603          	lbu	a2,0(a0)
 402:	fd06079b          	addiw	a5,a2,-48
 406:	0ff7f793          	andi	a5,a5,255
 40a:	4725                	li	a4,9
 40c:	02f76963          	bltu	a4,a5,43e <atoi+0x46>
 410:	86aa                	mv	a3,a0
  n = 0;
 412:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 414:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 416:	0685                	addi	a3,a3,1
 418:	0025179b          	slliw	a5,a0,0x2
 41c:	9fa9                	addw	a5,a5,a0
 41e:	0017979b          	slliw	a5,a5,0x1
 422:	9fb1                	addw	a5,a5,a2
 424:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 428:	0006c603          	lbu	a2,0(a3)
 42c:	fd06071b          	addiw	a4,a2,-48
 430:	0ff77713          	andi	a4,a4,255
 434:	fee5f1e3          	bgeu	a1,a4,416 <atoi+0x1e>
  return n;
}
 438:	6422                	ld	s0,8(sp)
 43a:	0141                	addi	sp,sp,16
 43c:	8082                	ret
  n = 0;
 43e:	4501                	li	a0,0
 440:	bfe5                	j	438 <atoi+0x40>

0000000000000442 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 442:	1141                	addi	sp,sp,-16
 444:	e422                	sd	s0,8(sp)
 446:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 448:	02b57663          	bgeu	a0,a1,474 <memmove+0x32>
    while(n-- > 0)
 44c:	02c05163          	blez	a2,46e <memmove+0x2c>
 450:	fff6079b          	addiw	a5,a2,-1
 454:	1782                	slli	a5,a5,0x20
 456:	9381                	srli	a5,a5,0x20
 458:	0785                	addi	a5,a5,1
 45a:	97aa                	add	a5,a5,a0
  dst = vdst;
 45c:	872a                	mv	a4,a0
      *dst++ = *src++;
 45e:	0585                	addi	a1,a1,1
 460:	0705                	addi	a4,a4,1
 462:	fff5c683          	lbu	a3,-1(a1)
 466:	fed70fa3          	sb	a3,-1(a4) # 1fff <__global_pointer$+0xcee>
    while(n-- > 0)
 46a:	fee79ae3          	bne	a5,a4,45e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 46e:	6422                	ld	s0,8(sp)
 470:	0141                	addi	sp,sp,16
 472:	8082                	ret
    dst += n;
 474:	00c50733          	add	a4,a0,a2
    src += n;
 478:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 47a:	fec05ae3          	blez	a2,46e <memmove+0x2c>
 47e:	fff6079b          	addiw	a5,a2,-1
 482:	1782                	slli	a5,a5,0x20
 484:	9381                	srli	a5,a5,0x20
 486:	fff7c793          	not	a5,a5
 48a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 48c:	15fd                	addi	a1,a1,-1
 48e:	177d                	addi	a4,a4,-1
 490:	0005c683          	lbu	a3,0(a1)
 494:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 498:	fee79ae3          	bne	a5,a4,48c <memmove+0x4a>
 49c:	bfc9                	j	46e <memmove+0x2c>

000000000000049e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 49e:	1141                	addi	sp,sp,-16
 4a0:	e422                	sd	s0,8(sp)
 4a2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4a4:	ca05                	beqz	a2,4d4 <memcmp+0x36>
 4a6:	fff6069b          	addiw	a3,a2,-1
 4aa:	1682                	slli	a3,a3,0x20
 4ac:	9281                	srli	a3,a3,0x20
 4ae:	0685                	addi	a3,a3,1
 4b0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4b2:	00054783          	lbu	a5,0(a0)
 4b6:	0005c703          	lbu	a4,0(a1)
 4ba:	00e79863          	bne	a5,a4,4ca <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4be:	0505                	addi	a0,a0,1
    p2++;
 4c0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4c2:	fed518e3          	bne	a0,a3,4b2 <memcmp+0x14>
  }
  return 0;
 4c6:	4501                	li	a0,0
 4c8:	a019                	j	4ce <memcmp+0x30>
      return *p1 - *p2;
 4ca:	40e7853b          	subw	a0,a5,a4
}
 4ce:	6422                	ld	s0,8(sp)
 4d0:	0141                	addi	sp,sp,16
 4d2:	8082                	ret
  return 0;
 4d4:	4501                	li	a0,0
 4d6:	bfe5                	j	4ce <memcmp+0x30>

00000000000004d8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4d8:	1141                	addi	sp,sp,-16
 4da:	e406                	sd	ra,8(sp)
 4dc:	e022                	sd	s0,0(sp)
 4de:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4e0:	00000097          	auipc	ra,0x0
 4e4:	f62080e7          	jalr	-158(ra) # 442 <memmove>
}
 4e8:	60a2                	ld	ra,8(sp)
 4ea:	6402                	ld	s0,0(sp)
 4ec:	0141                	addi	sp,sp,16
 4ee:	8082                	ret

00000000000004f0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4f0:	4885                	li	a7,1
 ecall
 4f2:	00000073          	ecall
 ret
 4f6:	8082                	ret

00000000000004f8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 4f8:	4889                	li	a7,2
 ecall
 4fa:	00000073          	ecall
 ret
 4fe:	8082                	ret

0000000000000500 <wait>:
.global wait
wait:
 li a7, SYS_wait
 500:	488d                	li	a7,3
 ecall
 502:	00000073          	ecall
 ret
 506:	8082                	ret

0000000000000508 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 508:	4891                	li	a7,4
 ecall
 50a:	00000073          	ecall
 ret
 50e:	8082                	ret

0000000000000510 <read>:
.global read
read:
 li a7, SYS_read
 510:	4895                	li	a7,5
 ecall
 512:	00000073          	ecall
 ret
 516:	8082                	ret

0000000000000518 <write>:
.global write
write:
 li a7, SYS_write
 518:	48c1                	li	a7,16
 ecall
 51a:	00000073          	ecall
 ret
 51e:	8082                	ret

0000000000000520 <close>:
.global close
close:
 li a7, SYS_close
 520:	48d5                	li	a7,21
 ecall
 522:	00000073          	ecall
 ret
 526:	8082                	ret

0000000000000528 <kill>:
.global kill
kill:
 li a7, SYS_kill
 528:	4899                	li	a7,6
 ecall
 52a:	00000073          	ecall
 ret
 52e:	8082                	ret

0000000000000530 <exec>:
.global exec
exec:
 li a7, SYS_exec
 530:	489d                	li	a7,7
 ecall
 532:	00000073          	ecall
 ret
 536:	8082                	ret

0000000000000538 <open>:
.global open
open:
 li a7, SYS_open
 538:	48bd                	li	a7,15
 ecall
 53a:	00000073          	ecall
 ret
 53e:	8082                	ret

0000000000000540 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 540:	48c5                	li	a7,17
 ecall
 542:	00000073          	ecall
 ret
 546:	8082                	ret

0000000000000548 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 548:	48c9                	li	a7,18
 ecall
 54a:	00000073          	ecall
 ret
 54e:	8082                	ret

0000000000000550 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 550:	48a1                	li	a7,8
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <link>:
.global link
link:
 li a7, SYS_link
 558:	48cd                	li	a7,19
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 560:	48d1                	li	a7,20
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 568:	48a5                	li	a7,9
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <dup>:
.global dup
dup:
 li a7, SYS_dup
 570:	48a9                	li	a7,10
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 578:	48ad                	li	a7,11
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 580:	48b1                	li	a7,12
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 588:	48b5                	li	a7,13
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 590:	48b9                	li	a7,14
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <ps>:
.global ps
ps:
 li a7, SYS_ps
 598:	48d9                	li	a7,22
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5a0:	1101                	addi	sp,sp,-32
 5a2:	ec06                	sd	ra,24(sp)
 5a4:	e822                	sd	s0,16(sp)
 5a6:	1000                	addi	s0,sp,32
 5a8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5ac:	4605                	li	a2,1
 5ae:	fef40593          	addi	a1,s0,-17
 5b2:	00000097          	auipc	ra,0x0
 5b6:	f66080e7          	jalr	-154(ra) # 518 <write>
}
 5ba:	60e2                	ld	ra,24(sp)
 5bc:	6442                	ld	s0,16(sp)
 5be:	6105                	addi	sp,sp,32
 5c0:	8082                	ret

00000000000005c2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5c2:	7139                	addi	sp,sp,-64
 5c4:	fc06                	sd	ra,56(sp)
 5c6:	f822                	sd	s0,48(sp)
 5c8:	f426                	sd	s1,40(sp)
 5ca:	f04a                	sd	s2,32(sp)
 5cc:	ec4e                	sd	s3,24(sp)
 5ce:	0080                	addi	s0,sp,64
 5d0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5d2:	c299                	beqz	a3,5d8 <printint+0x16>
 5d4:	0805c863          	bltz	a1,664 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5d8:	2581                	sext.w	a1,a1
  neg = 0;
 5da:	4881                	li	a7,0
 5dc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5e0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5e2:	2601                	sext.w	a2,a2
 5e4:	00000517          	auipc	a0,0x0
 5e8:	51c50513          	addi	a0,a0,1308 # b00 <digits>
 5ec:	883a                	mv	a6,a4
 5ee:	2705                	addiw	a4,a4,1
 5f0:	02c5f7bb          	remuw	a5,a1,a2
 5f4:	1782                	slli	a5,a5,0x20
 5f6:	9381                	srli	a5,a5,0x20
 5f8:	97aa                	add	a5,a5,a0
 5fa:	0007c783          	lbu	a5,0(a5)
 5fe:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 602:	0005879b          	sext.w	a5,a1
 606:	02c5d5bb          	divuw	a1,a1,a2
 60a:	0685                	addi	a3,a3,1
 60c:	fec7f0e3          	bgeu	a5,a2,5ec <printint+0x2a>
  if(neg)
 610:	00088b63          	beqz	a7,626 <printint+0x64>
    buf[i++] = '-';
 614:	fd040793          	addi	a5,s0,-48
 618:	973e                	add	a4,a4,a5
 61a:	02d00793          	li	a5,45
 61e:	fef70823          	sb	a5,-16(a4)
 622:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 626:	02e05863          	blez	a4,656 <printint+0x94>
 62a:	fc040793          	addi	a5,s0,-64
 62e:	00e78933          	add	s2,a5,a4
 632:	fff78993          	addi	s3,a5,-1
 636:	99ba                	add	s3,s3,a4
 638:	377d                	addiw	a4,a4,-1
 63a:	1702                	slli	a4,a4,0x20
 63c:	9301                	srli	a4,a4,0x20
 63e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 642:	fff94583          	lbu	a1,-1(s2)
 646:	8526                	mv	a0,s1
 648:	00000097          	auipc	ra,0x0
 64c:	f58080e7          	jalr	-168(ra) # 5a0 <putc>
  while(--i >= 0)
 650:	197d                	addi	s2,s2,-1
 652:	ff3918e3          	bne	s2,s3,642 <printint+0x80>
}
 656:	70e2                	ld	ra,56(sp)
 658:	7442                	ld	s0,48(sp)
 65a:	74a2                	ld	s1,40(sp)
 65c:	7902                	ld	s2,32(sp)
 65e:	69e2                	ld	s3,24(sp)
 660:	6121                	addi	sp,sp,64
 662:	8082                	ret
    x = -xx;
 664:	40b005bb          	negw	a1,a1
    neg = 1;
 668:	4885                	li	a7,1
    x = -xx;
 66a:	bf8d                	j	5dc <printint+0x1a>

000000000000066c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 66c:	7119                	addi	sp,sp,-128
 66e:	fc86                	sd	ra,120(sp)
 670:	f8a2                	sd	s0,112(sp)
 672:	f4a6                	sd	s1,104(sp)
 674:	f0ca                	sd	s2,96(sp)
 676:	ecce                	sd	s3,88(sp)
 678:	e8d2                	sd	s4,80(sp)
 67a:	e4d6                	sd	s5,72(sp)
 67c:	e0da                	sd	s6,64(sp)
 67e:	fc5e                	sd	s7,56(sp)
 680:	f862                	sd	s8,48(sp)
 682:	f466                	sd	s9,40(sp)
 684:	f06a                	sd	s10,32(sp)
 686:	ec6e                	sd	s11,24(sp)
 688:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 68a:	0005c903          	lbu	s2,0(a1)
 68e:	18090f63          	beqz	s2,82c <vprintf+0x1c0>
 692:	8aaa                	mv	s5,a0
 694:	8b32                	mv	s6,a2
 696:	00158493          	addi	s1,a1,1
  state = 0;
 69a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 69c:	02500a13          	li	s4,37
      if(c == 'd'){
 6a0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6a4:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6a8:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6ac:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6b0:	00000b97          	auipc	s7,0x0
 6b4:	450b8b93          	addi	s7,s7,1104 # b00 <digits>
 6b8:	a839                	j	6d6 <vprintf+0x6a>
        putc(fd, c);
 6ba:	85ca                	mv	a1,s2
 6bc:	8556                	mv	a0,s5
 6be:	00000097          	auipc	ra,0x0
 6c2:	ee2080e7          	jalr	-286(ra) # 5a0 <putc>
 6c6:	a019                	j	6cc <vprintf+0x60>
    } else if(state == '%'){
 6c8:	01498f63          	beq	s3,s4,6e6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6cc:	0485                	addi	s1,s1,1
 6ce:	fff4c903          	lbu	s2,-1(s1)
 6d2:	14090d63          	beqz	s2,82c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6d6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6da:	fe0997e3          	bnez	s3,6c8 <vprintf+0x5c>
      if(c == '%'){
 6de:	fd479ee3          	bne	a5,s4,6ba <vprintf+0x4e>
        state = '%';
 6e2:	89be                	mv	s3,a5
 6e4:	b7e5                	j	6cc <vprintf+0x60>
      if(c == 'd'){
 6e6:	05878063          	beq	a5,s8,726 <vprintf+0xba>
      } else if(c == 'l') {
 6ea:	05978c63          	beq	a5,s9,742 <vprintf+0xd6>
      } else if(c == 'x') {
 6ee:	07a78863          	beq	a5,s10,75e <vprintf+0xf2>
      } else if(c == 'p') {
 6f2:	09b78463          	beq	a5,s11,77a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6f6:	07300713          	li	a4,115
 6fa:	0ce78663          	beq	a5,a4,7c6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6fe:	06300713          	li	a4,99
 702:	0ee78e63          	beq	a5,a4,7fe <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 706:	11478863          	beq	a5,s4,816 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 70a:	85d2                	mv	a1,s4
 70c:	8556                	mv	a0,s5
 70e:	00000097          	auipc	ra,0x0
 712:	e92080e7          	jalr	-366(ra) # 5a0 <putc>
        putc(fd, c);
 716:	85ca                	mv	a1,s2
 718:	8556                	mv	a0,s5
 71a:	00000097          	auipc	ra,0x0
 71e:	e86080e7          	jalr	-378(ra) # 5a0 <putc>
      }
      state = 0;
 722:	4981                	li	s3,0
 724:	b765                	j	6cc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 726:	008b0913          	addi	s2,s6,8
 72a:	4685                	li	a3,1
 72c:	4629                	li	a2,10
 72e:	000b2583          	lw	a1,0(s6)
 732:	8556                	mv	a0,s5
 734:	00000097          	auipc	ra,0x0
 738:	e8e080e7          	jalr	-370(ra) # 5c2 <printint>
 73c:	8b4a                	mv	s6,s2
      state = 0;
 73e:	4981                	li	s3,0
 740:	b771                	j	6cc <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 742:	008b0913          	addi	s2,s6,8
 746:	4681                	li	a3,0
 748:	4629                	li	a2,10
 74a:	000b2583          	lw	a1,0(s6)
 74e:	8556                	mv	a0,s5
 750:	00000097          	auipc	ra,0x0
 754:	e72080e7          	jalr	-398(ra) # 5c2 <printint>
 758:	8b4a                	mv	s6,s2
      state = 0;
 75a:	4981                	li	s3,0
 75c:	bf85                	j	6cc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 75e:	008b0913          	addi	s2,s6,8
 762:	4681                	li	a3,0
 764:	4641                	li	a2,16
 766:	000b2583          	lw	a1,0(s6)
 76a:	8556                	mv	a0,s5
 76c:	00000097          	auipc	ra,0x0
 770:	e56080e7          	jalr	-426(ra) # 5c2 <printint>
 774:	8b4a                	mv	s6,s2
      state = 0;
 776:	4981                	li	s3,0
 778:	bf91                	j	6cc <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 77a:	008b0793          	addi	a5,s6,8
 77e:	f8f43423          	sd	a5,-120(s0)
 782:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 786:	03000593          	li	a1,48
 78a:	8556                	mv	a0,s5
 78c:	00000097          	auipc	ra,0x0
 790:	e14080e7          	jalr	-492(ra) # 5a0 <putc>
  putc(fd, 'x');
 794:	85ea                	mv	a1,s10
 796:	8556                	mv	a0,s5
 798:	00000097          	auipc	ra,0x0
 79c:	e08080e7          	jalr	-504(ra) # 5a0 <putc>
 7a0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7a2:	03c9d793          	srli	a5,s3,0x3c
 7a6:	97de                	add	a5,a5,s7
 7a8:	0007c583          	lbu	a1,0(a5)
 7ac:	8556                	mv	a0,s5
 7ae:	00000097          	auipc	ra,0x0
 7b2:	df2080e7          	jalr	-526(ra) # 5a0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7b6:	0992                	slli	s3,s3,0x4
 7b8:	397d                	addiw	s2,s2,-1
 7ba:	fe0914e3          	bnez	s2,7a2 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7be:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7c2:	4981                	li	s3,0
 7c4:	b721                	j	6cc <vprintf+0x60>
        s = va_arg(ap, char*);
 7c6:	008b0993          	addi	s3,s6,8
 7ca:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7ce:	02090163          	beqz	s2,7f0 <vprintf+0x184>
        while(*s != 0){
 7d2:	00094583          	lbu	a1,0(s2)
 7d6:	c9a1                	beqz	a1,826 <vprintf+0x1ba>
          putc(fd, *s);
 7d8:	8556                	mv	a0,s5
 7da:	00000097          	auipc	ra,0x0
 7de:	dc6080e7          	jalr	-570(ra) # 5a0 <putc>
          s++;
 7e2:	0905                	addi	s2,s2,1
        while(*s != 0){
 7e4:	00094583          	lbu	a1,0(s2)
 7e8:	f9e5                	bnez	a1,7d8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7ea:	8b4e                	mv	s6,s3
      state = 0;
 7ec:	4981                	li	s3,0
 7ee:	bdf9                	j	6cc <vprintf+0x60>
          s = "(null)";
 7f0:	00000917          	auipc	s2,0x0
 7f4:	30890913          	addi	s2,s2,776 # af8 <malloc+0x1c2>
        while(*s != 0){
 7f8:	02800593          	li	a1,40
 7fc:	bff1                	j	7d8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7fe:	008b0913          	addi	s2,s6,8
 802:	000b4583          	lbu	a1,0(s6)
 806:	8556                	mv	a0,s5
 808:	00000097          	auipc	ra,0x0
 80c:	d98080e7          	jalr	-616(ra) # 5a0 <putc>
 810:	8b4a                	mv	s6,s2
      state = 0;
 812:	4981                	li	s3,0
 814:	bd65                	j	6cc <vprintf+0x60>
        putc(fd, c);
 816:	85d2                	mv	a1,s4
 818:	8556                	mv	a0,s5
 81a:	00000097          	auipc	ra,0x0
 81e:	d86080e7          	jalr	-634(ra) # 5a0 <putc>
      state = 0;
 822:	4981                	li	s3,0
 824:	b565                	j	6cc <vprintf+0x60>
        s = va_arg(ap, char*);
 826:	8b4e                	mv	s6,s3
      state = 0;
 828:	4981                	li	s3,0
 82a:	b54d                	j	6cc <vprintf+0x60>
    }
  }
}
 82c:	70e6                	ld	ra,120(sp)
 82e:	7446                	ld	s0,112(sp)
 830:	74a6                	ld	s1,104(sp)
 832:	7906                	ld	s2,96(sp)
 834:	69e6                	ld	s3,88(sp)
 836:	6a46                	ld	s4,80(sp)
 838:	6aa6                	ld	s5,72(sp)
 83a:	6b06                	ld	s6,64(sp)
 83c:	7be2                	ld	s7,56(sp)
 83e:	7c42                	ld	s8,48(sp)
 840:	7ca2                	ld	s9,40(sp)
 842:	7d02                	ld	s10,32(sp)
 844:	6de2                	ld	s11,24(sp)
 846:	6109                	addi	sp,sp,128
 848:	8082                	ret

000000000000084a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 84a:	715d                	addi	sp,sp,-80
 84c:	ec06                	sd	ra,24(sp)
 84e:	e822                	sd	s0,16(sp)
 850:	1000                	addi	s0,sp,32
 852:	e010                	sd	a2,0(s0)
 854:	e414                	sd	a3,8(s0)
 856:	e818                	sd	a4,16(s0)
 858:	ec1c                	sd	a5,24(s0)
 85a:	03043023          	sd	a6,32(s0)
 85e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 862:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 866:	8622                	mv	a2,s0
 868:	00000097          	auipc	ra,0x0
 86c:	e04080e7          	jalr	-508(ra) # 66c <vprintf>
}
 870:	60e2                	ld	ra,24(sp)
 872:	6442                	ld	s0,16(sp)
 874:	6161                	addi	sp,sp,80
 876:	8082                	ret

0000000000000878 <printf>:

void
printf(const char *fmt, ...)
{
 878:	711d                	addi	sp,sp,-96
 87a:	ec06                	sd	ra,24(sp)
 87c:	e822                	sd	s0,16(sp)
 87e:	1000                	addi	s0,sp,32
 880:	e40c                	sd	a1,8(s0)
 882:	e810                	sd	a2,16(s0)
 884:	ec14                	sd	a3,24(s0)
 886:	f018                	sd	a4,32(s0)
 888:	f41c                	sd	a5,40(s0)
 88a:	03043823          	sd	a6,48(s0)
 88e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 892:	00840613          	addi	a2,s0,8
 896:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 89a:	85aa                	mv	a1,a0
 89c:	4505                	li	a0,1
 89e:	00000097          	auipc	ra,0x0
 8a2:	dce080e7          	jalr	-562(ra) # 66c <vprintf>
}
 8a6:	60e2                	ld	ra,24(sp)
 8a8:	6442                	ld	s0,16(sp)
 8aa:	6125                	addi	sp,sp,96
 8ac:	8082                	ret

00000000000008ae <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8ae:	1141                	addi	sp,sp,-16
 8b0:	e422                	sd	s0,8(sp)
 8b2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8b4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8b8:	00000797          	auipc	a5,0x0
 8bc:	2807b783          	ld	a5,640(a5) # b38 <freep>
 8c0:	a805                	j	8f0 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8c2:	4618                	lw	a4,8(a2)
 8c4:	9db9                	addw	a1,a1,a4
 8c6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8ca:	6398                	ld	a4,0(a5)
 8cc:	6318                	ld	a4,0(a4)
 8ce:	fee53823          	sd	a4,-16(a0)
 8d2:	a091                	j	916 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8d4:	ff852703          	lw	a4,-8(a0)
 8d8:	9e39                	addw	a2,a2,a4
 8da:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8dc:	ff053703          	ld	a4,-16(a0)
 8e0:	e398                	sd	a4,0(a5)
 8e2:	a099                	j	928 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8e4:	6398                	ld	a4,0(a5)
 8e6:	00e7e463          	bltu	a5,a4,8ee <free+0x40>
 8ea:	00e6ea63          	bltu	a3,a4,8fe <free+0x50>
{
 8ee:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8f0:	fed7fae3          	bgeu	a5,a3,8e4 <free+0x36>
 8f4:	6398                	ld	a4,0(a5)
 8f6:	00e6e463          	bltu	a3,a4,8fe <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8fa:	fee7eae3          	bltu	a5,a4,8ee <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8fe:	ff852583          	lw	a1,-8(a0)
 902:	6390                	ld	a2,0(a5)
 904:	02059713          	slli	a4,a1,0x20
 908:	9301                	srli	a4,a4,0x20
 90a:	0712                	slli	a4,a4,0x4
 90c:	9736                	add	a4,a4,a3
 90e:	fae60ae3          	beq	a2,a4,8c2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 912:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 916:	4790                	lw	a2,8(a5)
 918:	02061713          	slli	a4,a2,0x20
 91c:	9301                	srli	a4,a4,0x20
 91e:	0712                	slli	a4,a4,0x4
 920:	973e                	add	a4,a4,a5
 922:	fae689e3          	beq	a3,a4,8d4 <free+0x26>
  } else
    p->s.ptr = bp;
 926:	e394                	sd	a3,0(a5)
  freep = p;
 928:	00000717          	auipc	a4,0x0
 92c:	20f73823          	sd	a5,528(a4) # b38 <freep>
}
 930:	6422                	ld	s0,8(sp)
 932:	0141                	addi	sp,sp,16
 934:	8082                	ret

0000000000000936 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 936:	7139                	addi	sp,sp,-64
 938:	fc06                	sd	ra,56(sp)
 93a:	f822                	sd	s0,48(sp)
 93c:	f426                	sd	s1,40(sp)
 93e:	f04a                	sd	s2,32(sp)
 940:	ec4e                	sd	s3,24(sp)
 942:	e852                	sd	s4,16(sp)
 944:	e456                	sd	s5,8(sp)
 946:	e05a                	sd	s6,0(sp)
 948:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 94a:	02051493          	slli	s1,a0,0x20
 94e:	9081                	srli	s1,s1,0x20
 950:	04bd                	addi	s1,s1,15
 952:	8091                	srli	s1,s1,0x4
 954:	0014899b          	addiw	s3,s1,1
 958:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 95a:	00000517          	auipc	a0,0x0
 95e:	1de53503          	ld	a0,478(a0) # b38 <freep>
 962:	c515                	beqz	a0,98e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 964:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 966:	4798                	lw	a4,8(a5)
 968:	02977f63          	bgeu	a4,s1,9a6 <malloc+0x70>
 96c:	8a4e                	mv	s4,s3
 96e:	0009871b          	sext.w	a4,s3
 972:	6685                	lui	a3,0x1
 974:	00d77363          	bgeu	a4,a3,97a <malloc+0x44>
 978:	6a05                	lui	s4,0x1
 97a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 97e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 982:	00000917          	auipc	s2,0x0
 986:	1b690913          	addi	s2,s2,438 # b38 <freep>
  if(p == (char*)-1)
 98a:	5afd                	li	s5,-1
 98c:	a88d                	j	9fe <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 98e:	00008797          	auipc	a5,0x8
 992:	39278793          	addi	a5,a5,914 # 8d20 <base>
 996:	00000717          	auipc	a4,0x0
 99a:	1af73123          	sd	a5,418(a4) # b38 <freep>
 99e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9a0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9a4:	b7e1                	j	96c <malloc+0x36>
      if(p->s.size == nunits)
 9a6:	02e48b63          	beq	s1,a4,9dc <malloc+0xa6>
        p->s.size -= nunits;
 9aa:	4137073b          	subw	a4,a4,s3
 9ae:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9b0:	1702                	slli	a4,a4,0x20
 9b2:	9301                	srli	a4,a4,0x20
 9b4:	0712                	slli	a4,a4,0x4
 9b6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9b8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9bc:	00000717          	auipc	a4,0x0
 9c0:	16a73e23          	sd	a0,380(a4) # b38 <freep>
      return (void*)(p + 1);
 9c4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9c8:	70e2                	ld	ra,56(sp)
 9ca:	7442                	ld	s0,48(sp)
 9cc:	74a2                	ld	s1,40(sp)
 9ce:	7902                	ld	s2,32(sp)
 9d0:	69e2                	ld	s3,24(sp)
 9d2:	6a42                	ld	s4,16(sp)
 9d4:	6aa2                	ld	s5,8(sp)
 9d6:	6b02                	ld	s6,0(sp)
 9d8:	6121                	addi	sp,sp,64
 9da:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9dc:	6398                	ld	a4,0(a5)
 9de:	e118                	sd	a4,0(a0)
 9e0:	bff1                	j	9bc <malloc+0x86>
  hp->s.size = nu;
 9e2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9e6:	0541                	addi	a0,a0,16
 9e8:	00000097          	auipc	ra,0x0
 9ec:	ec6080e7          	jalr	-314(ra) # 8ae <free>
  return freep;
 9f0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9f4:	d971                	beqz	a0,9c8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9f6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9f8:	4798                	lw	a4,8(a5)
 9fa:	fa9776e3          	bgeu	a4,s1,9a6 <malloc+0x70>
    if(p == freep)
 9fe:	00093703          	ld	a4,0(s2)
 a02:	853e                	mv	a0,a5
 a04:	fef719e3          	bne	a4,a5,9f6 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a08:	8552                	mv	a0,s4
 a0a:	00000097          	auipc	ra,0x0
 a0e:	b76080e7          	jalr	-1162(ra) # 580 <sbrk>
  if(p == (char*)-1)
 a12:	fd5518e3          	bne	a0,s5,9e2 <malloc+0xac>
        return 0;
 a16:	4501                	li	a0,0
 a18:	bf45                	j	9c8 <malloc+0x92>
