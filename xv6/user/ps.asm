
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/psinfo.h"

int main(int argc, char *argv[]) {
   0:	7165                	addi	sp,sp,-400
   2:	e706                	sd	ra,392(sp)
   4:	e322                	sd	s0,384(sp)
   6:	fea6                	sd	s1,376(sp)
   8:	faca                	sd	s2,368(sp)
   a:	f6ce                	sd	s3,360(sp)
   c:	f2d2                	sd	s4,352(sp)
   e:	eed6                	sd	s5,344(sp)
  10:	eada                	sd	s6,336(sp)
  12:	e6de                	sd	s7,328(sp)
  14:	e2e2                	sd	s8,320(sp)
  16:	fe66                	sd	s9,312(sp)
  18:	fa6a                	sd	s10,304(sp)
  1a:	f66e                	sd	s11,296(sp)
  1c:	0b00                	addi	s0,sp,400
    struct ps_proc ptable[MAX_PROC];
    struct ps_proc *p;
    int err;
    int items = 0;

    err = ps(ptable);
  1e:	e7840513          	addi	a0,s0,-392
  22:	00000097          	auipc	ra,0x0
  26:	4ce080e7          	jalr	1230(ra) # 4f0 <ps>
    if (err < 0) {
  2a:	06054763          	bltz	a0,98 <main+0x98>
        printf("Error getting ptable");
        exit(1);
    }

    p = &ptable[0];
    printf("Process Status\n");
  2e:	00001517          	auipc	a0,0x1
  32:	96250513          	addi	a0,a0,-1694 # 990 <malloc+0x102>
  36:	00000097          	auipc	ra,0x0
  3a:	79a080e7          	jalr	1946(ra) # 7d0 <printf>
    printf("name\tpid\tstate\t\tpriority\n");
  3e:	00001517          	auipc	a0,0x1
  42:	96250513          	addi	a0,a0,-1694 # 9a0 <malloc+0x112>
  46:	00000097          	auipc	ra,0x0
  4a:	78a080e7          	jalr	1930(ra) # 7d0 <printf>
    printf("=========================================\n");
  4e:	00001517          	auipc	a0,0x1
  52:	97250513          	addi	a0,a0,-1678 # 9c0 <malloc+0x132>
  56:	00000097          	auipc	ra,0x0
  5a:	77a080e7          	jalr	1914(ra) # 7d0 <printf>
    while (p != &ptable[MAX_PROC - 1] && p->state != 0) {
  5e:	e8440493          	addi	s1,s0,-380
    printf("=========================================\n");
  62:	4901                	li	s2,0
        printf("%s\t%d\t", p->name, p->pid);
  64:	00001b97          	auipc	s7,0x1
  68:	98cb8b93          	addi	s7,s7,-1652 # 9f0 <malloc+0x162>
  6c:	4b15                	li	s6,5
  6e:	00001a17          	auipc	s4,0x1
  72:	a12a0a13          	addi	s4,s4,-1518 # a80 <malloc+0x1f2>
            case 4:
                printf("%s ", "RUNNING");
                items++;
                break;
            case 5:
                printf("%s  ", "ZOMBIE");
  76:	00001d97          	auipc	s11,0x1
  7a:	9cad8d93          	addi	s11,s11,-1590 # a40 <malloc+0x1b2>
  7e:	00001d17          	auipc	s10,0x1
  82:	9cad0d13          	addi	s10,s10,-1590 # a48 <malloc+0x1ba>
                printf("%s ", "RUNNING");
  86:	00001c97          	auipc	s9,0x1
  8a:	9aac8c93          	addi	s9,s9,-1622 # a30 <malloc+0x1a2>
  8e:	00001c17          	auipc	s8,0x1
  92:	9aac0c13          	addi	s8,s8,-1622 # a38 <malloc+0x1aa>
  96:	a899                	j	ec <main+0xec>
        printf("Error getting ptable");
  98:	00001517          	auipc	a0,0x1
  9c:	8e050513          	addi	a0,a0,-1824 # 978 <malloc+0xea>
  a0:	00000097          	auipc	ra,0x0
  a4:	730080e7          	jalr	1840(ra) # 7d0 <printf>
        exit(1);
  a8:	4505                	li	a0,1
  aa:	00000097          	auipc	ra,0x0
  ae:	3a6080e7          	jalr	934(ra) # 450 <exit>
                printf("%s    ", "USED");
  b2:	00001597          	auipc	a1,0x1
  b6:	94658593          	addi	a1,a1,-1722 # 9f8 <malloc+0x16a>
  ba:	00001517          	auipc	a0,0x1
  be:	94650513          	addi	a0,a0,-1722 # a00 <malloc+0x172>
  c2:	00000097          	auipc	ra,0x0
  c6:	70e080e7          	jalr	1806(ra) # 7d0 <printf>
                items++;
  ca:	00190a9b          	addiw	s5,s2,1
                break;
            default:
                printf("ps test: FAILED\n");
                exit(1);
        }
        printf("\t%d\n", p->priority);
  ce:	ffc9a583          	lw	a1,-4(s3)
  d2:	00001517          	auipc	a0,0x1
  d6:	99650513          	addi	a0,a0,-1642 # a68 <malloc+0x1da>
  da:	00000097          	auipc	ra,0x0
  de:	6f6080e7          	jalr	1782(ra) # 7d0 <printf>
    while (p != &ptable[MAX_PROC - 1] && p->state != 0) {
  e2:	2905                	addiw	s2,s2,1
  e4:	04f1                	addi	s1,s1,28
  e6:	47a5                	li	a5,9
  e8:	0af90863          	beq	s2,a5,198 <main+0x198>
  ec:	00090a9b          	sext.w	s5,s2
  f0:	89a6                	mv	s3,s1
  f2:	ff44a783          	lw	a5,-12(s1)
  f6:	c3cd                	beqz	a5,198 <main+0x198>
        printf("%s\t%d\t", p->name, p->pid);
  f8:	ff84a603          	lw	a2,-8(s1)
  fc:	85a6                	mv	a1,s1
  fe:	855e                	mv	a0,s7
 100:	00000097          	auipc	ra,0x0
 104:	6d0080e7          	jalr	1744(ra) # 7d0 <printf>
        switch (p->state) {
 108:	ff44a783          	lw	a5,-12(s1)
 10c:	06fb6963          	bltu	s6,a5,17e <main+0x17e>
 110:	ff49e783          	lwu	a5,-12(s3)
 114:	078a                	slli	a5,a5,0x2
 116:	97d2                	add	a5,a5,s4
 118:	439c                	lw	a5,0(a5)
 11a:	97d2                	add	a5,a5,s4
 11c:	8782                	jr	a5
                printf("%s", "SLEEPING");
 11e:	00001597          	auipc	a1,0x1
 122:	8ea58593          	addi	a1,a1,-1814 # a08 <malloc+0x17a>
 126:	00001517          	auipc	a0,0x1
 12a:	8f250513          	addi	a0,a0,-1806 # a18 <malloc+0x18a>
 12e:	00000097          	auipc	ra,0x0
 132:	6a2080e7          	jalr	1698(ra) # 7d0 <printf>
                items++;
 136:	00190a9b          	addiw	s5,s2,1
                break;
 13a:	bf51                	j	ce <main+0xce>
                printf("%s", "RUNNABLE");
 13c:	00001597          	auipc	a1,0x1
 140:	8e458593          	addi	a1,a1,-1820 # a20 <malloc+0x192>
 144:	00001517          	auipc	a0,0x1
 148:	8d450513          	addi	a0,a0,-1836 # a18 <malloc+0x18a>
 14c:	00000097          	auipc	ra,0x0
 150:	684080e7          	jalr	1668(ra) # 7d0 <printf>
                items++;
 154:	00190a9b          	addiw	s5,s2,1
                break;
 158:	bf9d                	j	ce <main+0xce>
                printf("%s ", "RUNNING");
 15a:	85e6                	mv	a1,s9
 15c:	8562                	mv	a0,s8
 15e:	00000097          	auipc	ra,0x0
 162:	672080e7          	jalr	1650(ra) # 7d0 <printf>
                items++;
 166:	00190a9b          	addiw	s5,s2,1
                break;
 16a:	b795                	j	ce <main+0xce>
                printf("%s  ", "ZOMBIE");
 16c:	85ee                	mv	a1,s11
 16e:	856a                	mv	a0,s10
 170:	00000097          	auipc	ra,0x0
 174:	660080e7          	jalr	1632(ra) # 7d0 <printf>
                items++;
 178:	00190a9b          	addiw	s5,s2,1
                break;
 17c:	bf89                	j	ce <main+0xce>
                printf("ps test: FAILED\n");
 17e:	00001517          	auipc	a0,0x1
 182:	8d250513          	addi	a0,a0,-1838 # a50 <malloc+0x1c2>
 186:	00000097          	auipc	ra,0x0
 18a:	64a080e7          	jalr	1610(ra) # 7d0 <printf>
                exit(1);
 18e:	4505                	li	a0,1
 190:	00000097          	auipc	ra,0x0
 194:	2c0080e7          	jalr	704(ra) # 450 <exit>
        p++;
    }
    printf("=========================================\n");
 198:	00001517          	auipc	a0,0x1
 19c:	82850513          	addi	a0,a0,-2008 # 9c0 <malloc+0x132>
 1a0:	00000097          	auipc	ra,0x0
 1a4:	630080e7          	jalr	1584(ra) # 7d0 <printf>
    if (items >= 3)
 1a8:	4789                	li	a5,2
 1aa:	0157df63          	bge	a5,s5,1c8 <main+0x1c8>
        printf("ps test: OK\n");
 1ae:	00001517          	auipc	a0,0x1
 1b2:	8c250513          	addi	a0,a0,-1854 # a70 <malloc+0x1e2>
 1b6:	00000097          	auipc	ra,0x0
 1ba:	61a080e7          	jalr	1562(ra) # 7d0 <printf>
    else
        printf("ps test: FAILED\n");
    exit(0);
 1be:	4501                	li	a0,0
 1c0:	00000097          	auipc	ra,0x0
 1c4:	290080e7          	jalr	656(ra) # 450 <exit>
        printf("ps test: FAILED\n");
 1c8:	00001517          	auipc	a0,0x1
 1cc:	88850513          	addi	a0,a0,-1912 # a50 <malloc+0x1c2>
 1d0:	00000097          	auipc	ra,0x0
 1d4:	600080e7          	jalr	1536(ra) # 7d0 <printf>
 1d8:	b7dd                	j	1be <main+0x1be>

00000000000001da <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1da:	1141                	addi	sp,sp,-16
 1dc:	e422                	sd	s0,8(sp)
 1de:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1e0:	87aa                	mv	a5,a0
 1e2:	0585                	addi	a1,a1,1
 1e4:	0785                	addi	a5,a5,1
 1e6:	fff5c703          	lbu	a4,-1(a1)
 1ea:	fee78fa3          	sb	a4,-1(a5)
 1ee:	fb75                	bnez	a4,1e2 <strcpy+0x8>
    ;
  return os;
}
 1f0:	6422                	ld	s0,8(sp)
 1f2:	0141                	addi	sp,sp,16
 1f4:	8082                	ret

00000000000001f6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1f6:	1141                	addi	sp,sp,-16
 1f8:	e422                	sd	s0,8(sp)
 1fa:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1fc:	00054783          	lbu	a5,0(a0)
 200:	cb91                	beqz	a5,214 <strcmp+0x1e>
 202:	0005c703          	lbu	a4,0(a1)
 206:	00f71763          	bne	a4,a5,214 <strcmp+0x1e>
    p++, q++;
 20a:	0505                	addi	a0,a0,1
 20c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 20e:	00054783          	lbu	a5,0(a0)
 212:	fbe5                	bnez	a5,202 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 214:	0005c503          	lbu	a0,0(a1)
}
 218:	40a7853b          	subw	a0,a5,a0
 21c:	6422                	ld	s0,8(sp)
 21e:	0141                	addi	sp,sp,16
 220:	8082                	ret

0000000000000222 <strlen>:

uint
strlen(const char *s)
{
 222:	1141                	addi	sp,sp,-16
 224:	e422                	sd	s0,8(sp)
 226:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 228:	00054783          	lbu	a5,0(a0)
 22c:	cf91                	beqz	a5,248 <strlen+0x26>
 22e:	0505                	addi	a0,a0,1
 230:	87aa                	mv	a5,a0
 232:	4685                	li	a3,1
 234:	9e89                	subw	a3,a3,a0
 236:	00f6853b          	addw	a0,a3,a5
 23a:	0785                	addi	a5,a5,1
 23c:	fff7c703          	lbu	a4,-1(a5)
 240:	fb7d                	bnez	a4,236 <strlen+0x14>
    ;
  return n;
}
 242:	6422                	ld	s0,8(sp)
 244:	0141                	addi	sp,sp,16
 246:	8082                	ret
  for(n = 0; s[n]; n++)
 248:	4501                	li	a0,0
 24a:	bfe5                	j	242 <strlen+0x20>

000000000000024c <memset>:

void*
memset(void *dst, int c, uint n)
{
 24c:	1141                	addi	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 252:	ce09                	beqz	a2,26c <memset+0x20>
 254:	87aa                	mv	a5,a0
 256:	fff6071b          	addiw	a4,a2,-1
 25a:	1702                	slli	a4,a4,0x20
 25c:	9301                	srli	a4,a4,0x20
 25e:	0705                	addi	a4,a4,1
 260:	972a                	add	a4,a4,a0
    cdst[i] = c;
 262:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 266:	0785                	addi	a5,a5,1
 268:	fee79de3          	bne	a5,a4,262 <memset+0x16>
  }
  return dst;
}
 26c:	6422                	ld	s0,8(sp)
 26e:	0141                	addi	sp,sp,16
 270:	8082                	ret

0000000000000272 <strchr>:

char*
strchr(const char *s, char c)
{
 272:	1141                	addi	sp,sp,-16
 274:	e422                	sd	s0,8(sp)
 276:	0800                	addi	s0,sp,16
  for(; *s; s++)
 278:	00054783          	lbu	a5,0(a0)
 27c:	cb99                	beqz	a5,292 <strchr+0x20>
    if(*s == c)
 27e:	00f58763          	beq	a1,a5,28c <strchr+0x1a>
  for(; *s; s++)
 282:	0505                	addi	a0,a0,1
 284:	00054783          	lbu	a5,0(a0)
 288:	fbfd                	bnez	a5,27e <strchr+0xc>
      return (char*)s;
  return 0;
 28a:	4501                	li	a0,0
}
 28c:	6422                	ld	s0,8(sp)
 28e:	0141                	addi	sp,sp,16
 290:	8082                	ret
  return 0;
 292:	4501                	li	a0,0
 294:	bfe5                	j	28c <strchr+0x1a>

0000000000000296 <gets>:

char*
gets(char *buf, int max)
{
 296:	711d                	addi	sp,sp,-96
 298:	ec86                	sd	ra,88(sp)
 29a:	e8a2                	sd	s0,80(sp)
 29c:	e4a6                	sd	s1,72(sp)
 29e:	e0ca                	sd	s2,64(sp)
 2a0:	fc4e                	sd	s3,56(sp)
 2a2:	f852                	sd	s4,48(sp)
 2a4:	f456                	sd	s5,40(sp)
 2a6:	f05a                	sd	s6,32(sp)
 2a8:	ec5e                	sd	s7,24(sp)
 2aa:	1080                	addi	s0,sp,96
 2ac:	8baa                	mv	s7,a0
 2ae:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2b0:	892a                	mv	s2,a0
 2b2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2b4:	4aa9                	li	s5,10
 2b6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2b8:	89a6                	mv	s3,s1
 2ba:	2485                	addiw	s1,s1,1
 2bc:	0344d863          	bge	s1,s4,2ec <gets+0x56>
    cc = read(0, &c, 1);
 2c0:	4605                	li	a2,1
 2c2:	faf40593          	addi	a1,s0,-81
 2c6:	4501                	li	a0,0
 2c8:	00000097          	auipc	ra,0x0
 2cc:	1a0080e7          	jalr	416(ra) # 468 <read>
    if(cc < 1)
 2d0:	00a05e63          	blez	a0,2ec <gets+0x56>
    buf[i++] = c;
 2d4:	faf44783          	lbu	a5,-81(s0)
 2d8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2dc:	01578763          	beq	a5,s5,2ea <gets+0x54>
 2e0:	0905                	addi	s2,s2,1
 2e2:	fd679be3          	bne	a5,s6,2b8 <gets+0x22>
  for(i=0; i+1 < max; ){
 2e6:	89a6                	mv	s3,s1
 2e8:	a011                	j	2ec <gets+0x56>
 2ea:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2ec:	99de                	add	s3,s3,s7
 2ee:	00098023          	sb	zero,0(s3)
  return buf;
}
 2f2:	855e                	mv	a0,s7
 2f4:	60e6                	ld	ra,88(sp)
 2f6:	6446                	ld	s0,80(sp)
 2f8:	64a6                	ld	s1,72(sp)
 2fa:	6906                	ld	s2,64(sp)
 2fc:	79e2                	ld	s3,56(sp)
 2fe:	7a42                	ld	s4,48(sp)
 300:	7aa2                	ld	s5,40(sp)
 302:	7b02                	ld	s6,32(sp)
 304:	6be2                	ld	s7,24(sp)
 306:	6125                	addi	sp,sp,96
 308:	8082                	ret

000000000000030a <stat>:

int
stat(const char *n, struct stat *st)
{
 30a:	1101                	addi	sp,sp,-32
 30c:	ec06                	sd	ra,24(sp)
 30e:	e822                	sd	s0,16(sp)
 310:	e426                	sd	s1,8(sp)
 312:	e04a                	sd	s2,0(sp)
 314:	1000                	addi	s0,sp,32
 316:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 318:	4581                	li	a1,0
 31a:	00000097          	auipc	ra,0x0
 31e:	176080e7          	jalr	374(ra) # 490 <open>
  if(fd < 0)
 322:	02054563          	bltz	a0,34c <stat+0x42>
 326:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 328:	85ca                	mv	a1,s2
 32a:	00000097          	auipc	ra,0x0
 32e:	17e080e7          	jalr	382(ra) # 4a8 <fstat>
 332:	892a                	mv	s2,a0
  close(fd);
 334:	8526                	mv	a0,s1
 336:	00000097          	auipc	ra,0x0
 33a:	142080e7          	jalr	322(ra) # 478 <close>
  return r;
}
 33e:	854a                	mv	a0,s2
 340:	60e2                	ld	ra,24(sp)
 342:	6442                	ld	s0,16(sp)
 344:	64a2                	ld	s1,8(sp)
 346:	6902                	ld	s2,0(sp)
 348:	6105                	addi	sp,sp,32
 34a:	8082                	ret
    return -1;
 34c:	597d                	li	s2,-1
 34e:	bfc5                	j	33e <stat+0x34>

0000000000000350 <atoi>:

int
atoi(const char *s)
{
 350:	1141                	addi	sp,sp,-16
 352:	e422                	sd	s0,8(sp)
 354:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 356:	00054603          	lbu	a2,0(a0)
 35a:	fd06079b          	addiw	a5,a2,-48
 35e:	0ff7f793          	andi	a5,a5,255
 362:	4725                	li	a4,9
 364:	02f76963          	bltu	a4,a5,396 <atoi+0x46>
 368:	86aa                	mv	a3,a0
  n = 0;
 36a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 36c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 36e:	0685                	addi	a3,a3,1
 370:	0025179b          	slliw	a5,a0,0x2
 374:	9fa9                	addw	a5,a5,a0
 376:	0017979b          	slliw	a5,a5,0x1
 37a:	9fb1                	addw	a5,a5,a2
 37c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 380:	0006c603          	lbu	a2,0(a3)
 384:	fd06071b          	addiw	a4,a2,-48
 388:	0ff77713          	andi	a4,a4,255
 38c:	fee5f1e3          	bgeu	a1,a4,36e <atoi+0x1e>
  return n;
}
 390:	6422                	ld	s0,8(sp)
 392:	0141                	addi	sp,sp,16
 394:	8082                	ret
  n = 0;
 396:	4501                	li	a0,0
 398:	bfe5                	j	390 <atoi+0x40>

000000000000039a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 39a:	1141                	addi	sp,sp,-16
 39c:	e422                	sd	s0,8(sp)
 39e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3a0:	02b57663          	bgeu	a0,a1,3cc <memmove+0x32>
    while(n-- > 0)
 3a4:	02c05163          	blez	a2,3c6 <memmove+0x2c>
 3a8:	fff6079b          	addiw	a5,a2,-1
 3ac:	1782                	slli	a5,a5,0x20
 3ae:	9381                	srli	a5,a5,0x20
 3b0:	0785                	addi	a5,a5,1
 3b2:	97aa                	add	a5,a5,a0
  dst = vdst;
 3b4:	872a                	mv	a4,a0
      *dst++ = *src++;
 3b6:	0585                	addi	a1,a1,1
 3b8:	0705                	addi	a4,a4,1
 3ba:	fff5c683          	lbu	a3,-1(a1)
 3be:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3c2:	fee79ae3          	bne	a5,a4,3b6 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3c6:	6422                	ld	s0,8(sp)
 3c8:	0141                	addi	sp,sp,16
 3ca:	8082                	ret
    dst += n;
 3cc:	00c50733          	add	a4,a0,a2
    src += n;
 3d0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3d2:	fec05ae3          	blez	a2,3c6 <memmove+0x2c>
 3d6:	fff6079b          	addiw	a5,a2,-1
 3da:	1782                	slli	a5,a5,0x20
 3dc:	9381                	srli	a5,a5,0x20
 3de:	fff7c793          	not	a5,a5
 3e2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3e4:	15fd                	addi	a1,a1,-1
 3e6:	177d                	addi	a4,a4,-1
 3e8:	0005c683          	lbu	a3,0(a1)
 3ec:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3f0:	fee79ae3          	bne	a5,a4,3e4 <memmove+0x4a>
 3f4:	bfc9                	j	3c6 <memmove+0x2c>

00000000000003f6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3f6:	1141                	addi	sp,sp,-16
 3f8:	e422                	sd	s0,8(sp)
 3fa:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3fc:	ca05                	beqz	a2,42c <memcmp+0x36>
 3fe:	fff6069b          	addiw	a3,a2,-1
 402:	1682                	slli	a3,a3,0x20
 404:	9281                	srli	a3,a3,0x20
 406:	0685                	addi	a3,a3,1
 408:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 40a:	00054783          	lbu	a5,0(a0)
 40e:	0005c703          	lbu	a4,0(a1)
 412:	00e79863          	bne	a5,a4,422 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 416:	0505                	addi	a0,a0,1
    p2++;
 418:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 41a:	fed518e3          	bne	a0,a3,40a <memcmp+0x14>
  }
  return 0;
 41e:	4501                	li	a0,0
 420:	a019                	j	426 <memcmp+0x30>
      return *p1 - *p2;
 422:	40e7853b          	subw	a0,a5,a4
}
 426:	6422                	ld	s0,8(sp)
 428:	0141                	addi	sp,sp,16
 42a:	8082                	ret
  return 0;
 42c:	4501                	li	a0,0
 42e:	bfe5                	j	426 <memcmp+0x30>

0000000000000430 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 430:	1141                	addi	sp,sp,-16
 432:	e406                	sd	ra,8(sp)
 434:	e022                	sd	s0,0(sp)
 436:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 438:	00000097          	auipc	ra,0x0
 43c:	f62080e7          	jalr	-158(ra) # 39a <memmove>
}
 440:	60a2                	ld	ra,8(sp)
 442:	6402                	ld	s0,0(sp)
 444:	0141                	addi	sp,sp,16
 446:	8082                	ret

0000000000000448 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 448:	4885                	li	a7,1
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <exit>:
.global exit
exit:
 li a7, SYS_exit
 450:	4889                	li	a7,2
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <wait>:
.global wait
wait:
 li a7, SYS_wait
 458:	488d                	li	a7,3
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 460:	4891                	li	a7,4
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <read>:
.global read
read:
 li a7, SYS_read
 468:	4895                	li	a7,5
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <write>:
.global write
write:
 li a7, SYS_write
 470:	48c1                	li	a7,16
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <close>:
.global close
close:
 li a7, SYS_close
 478:	48d5                	li	a7,21
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <kill>:
.global kill
kill:
 li a7, SYS_kill
 480:	4899                	li	a7,6
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <exec>:
.global exec
exec:
 li a7, SYS_exec
 488:	489d                	li	a7,7
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <open>:
.global open
open:
 li a7, SYS_open
 490:	48bd                	li	a7,15
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 498:	48c5                	li	a7,17
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4a0:	48c9                	li	a7,18
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4a8:	48a1                	li	a7,8
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <link>:
.global link
link:
 li a7, SYS_link
 4b0:	48cd                	li	a7,19
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4b8:	48d1                	li	a7,20
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4c0:	48a5                	li	a7,9
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4c8:	48a9                	li	a7,10
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4d0:	48ad                	li	a7,11
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4d8:	48b1                	li	a7,12
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4e0:	48b5                	li	a7,13
 ecall
 4e2:	00000073          	ecall
 ret
 4e6:	8082                	ret

00000000000004e8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4e8:	48b9                	li	a7,14
 ecall
 4ea:	00000073          	ecall
 ret
 4ee:	8082                	ret

00000000000004f0 <ps>:
.global ps
ps:
 li a7, SYS_ps
 4f0:	48d9                	li	a7,22
 ecall
 4f2:	00000073          	ecall
 ret
 4f6:	8082                	ret

00000000000004f8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4f8:	1101                	addi	sp,sp,-32
 4fa:	ec06                	sd	ra,24(sp)
 4fc:	e822                	sd	s0,16(sp)
 4fe:	1000                	addi	s0,sp,32
 500:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 504:	4605                	li	a2,1
 506:	fef40593          	addi	a1,s0,-17
 50a:	00000097          	auipc	ra,0x0
 50e:	f66080e7          	jalr	-154(ra) # 470 <write>
}
 512:	60e2                	ld	ra,24(sp)
 514:	6442                	ld	s0,16(sp)
 516:	6105                	addi	sp,sp,32
 518:	8082                	ret

000000000000051a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 51a:	7139                	addi	sp,sp,-64
 51c:	fc06                	sd	ra,56(sp)
 51e:	f822                	sd	s0,48(sp)
 520:	f426                	sd	s1,40(sp)
 522:	f04a                	sd	s2,32(sp)
 524:	ec4e                	sd	s3,24(sp)
 526:	0080                	addi	s0,sp,64
 528:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 52a:	c299                	beqz	a3,530 <printint+0x16>
 52c:	0805c863          	bltz	a1,5bc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 530:	2581                	sext.w	a1,a1
  neg = 0;
 532:	4881                	li	a7,0
 534:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 538:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 53a:	2601                	sext.w	a2,a2
 53c:	00000517          	auipc	a0,0x0
 540:	56450513          	addi	a0,a0,1380 # aa0 <digits>
 544:	883a                	mv	a6,a4
 546:	2705                	addiw	a4,a4,1
 548:	02c5f7bb          	remuw	a5,a1,a2
 54c:	1782                	slli	a5,a5,0x20
 54e:	9381                	srli	a5,a5,0x20
 550:	97aa                	add	a5,a5,a0
 552:	0007c783          	lbu	a5,0(a5)
 556:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 55a:	0005879b          	sext.w	a5,a1
 55e:	02c5d5bb          	divuw	a1,a1,a2
 562:	0685                	addi	a3,a3,1
 564:	fec7f0e3          	bgeu	a5,a2,544 <printint+0x2a>
  if(neg)
 568:	00088b63          	beqz	a7,57e <printint+0x64>
    buf[i++] = '-';
 56c:	fd040793          	addi	a5,s0,-48
 570:	973e                	add	a4,a4,a5
 572:	02d00793          	li	a5,45
 576:	fef70823          	sb	a5,-16(a4)
 57a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 57e:	02e05863          	blez	a4,5ae <printint+0x94>
 582:	fc040793          	addi	a5,s0,-64
 586:	00e78933          	add	s2,a5,a4
 58a:	fff78993          	addi	s3,a5,-1
 58e:	99ba                	add	s3,s3,a4
 590:	377d                	addiw	a4,a4,-1
 592:	1702                	slli	a4,a4,0x20
 594:	9301                	srli	a4,a4,0x20
 596:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 59a:	fff94583          	lbu	a1,-1(s2)
 59e:	8526                	mv	a0,s1
 5a0:	00000097          	auipc	ra,0x0
 5a4:	f58080e7          	jalr	-168(ra) # 4f8 <putc>
  while(--i >= 0)
 5a8:	197d                	addi	s2,s2,-1
 5aa:	ff3918e3          	bne	s2,s3,59a <printint+0x80>
}
 5ae:	70e2                	ld	ra,56(sp)
 5b0:	7442                	ld	s0,48(sp)
 5b2:	74a2                	ld	s1,40(sp)
 5b4:	7902                	ld	s2,32(sp)
 5b6:	69e2                	ld	s3,24(sp)
 5b8:	6121                	addi	sp,sp,64
 5ba:	8082                	ret
    x = -xx;
 5bc:	40b005bb          	negw	a1,a1
    neg = 1;
 5c0:	4885                	li	a7,1
    x = -xx;
 5c2:	bf8d                	j	534 <printint+0x1a>

00000000000005c4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5c4:	7119                	addi	sp,sp,-128
 5c6:	fc86                	sd	ra,120(sp)
 5c8:	f8a2                	sd	s0,112(sp)
 5ca:	f4a6                	sd	s1,104(sp)
 5cc:	f0ca                	sd	s2,96(sp)
 5ce:	ecce                	sd	s3,88(sp)
 5d0:	e8d2                	sd	s4,80(sp)
 5d2:	e4d6                	sd	s5,72(sp)
 5d4:	e0da                	sd	s6,64(sp)
 5d6:	fc5e                	sd	s7,56(sp)
 5d8:	f862                	sd	s8,48(sp)
 5da:	f466                	sd	s9,40(sp)
 5dc:	f06a                	sd	s10,32(sp)
 5de:	ec6e                	sd	s11,24(sp)
 5e0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5e2:	0005c903          	lbu	s2,0(a1)
 5e6:	18090f63          	beqz	s2,784 <vprintf+0x1c0>
 5ea:	8aaa                	mv	s5,a0
 5ec:	8b32                	mv	s6,a2
 5ee:	00158493          	addi	s1,a1,1
  state = 0;
 5f2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5f4:	02500a13          	li	s4,37
      if(c == 'd'){
 5f8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5fc:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 600:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 604:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 608:	00000b97          	auipc	s7,0x0
 60c:	498b8b93          	addi	s7,s7,1176 # aa0 <digits>
 610:	a839                	j	62e <vprintf+0x6a>
        putc(fd, c);
 612:	85ca                	mv	a1,s2
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	ee2080e7          	jalr	-286(ra) # 4f8 <putc>
 61e:	a019                	j	624 <vprintf+0x60>
    } else if(state == '%'){
 620:	01498f63          	beq	s3,s4,63e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 624:	0485                	addi	s1,s1,1
 626:	fff4c903          	lbu	s2,-1(s1)
 62a:	14090d63          	beqz	s2,784 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 62e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 632:	fe0997e3          	bnez	s3,620 <vprintf+0x5c>
      if(c == '%'){
 636:	fd479ee3          	bne	a5,s4,612 <vprintf+0x4e>
        state = '%';
 63a:	89be                	mv	s3,a5
 63c:	b7e5                	j	624 <vprintf+0x60>
      if(c == 'd'){
 63e:	05878063          	beq	a5,s8,67e <vprintf+0xba>
      } else if(c == 'l') {
 642:	05978c63          	beq	a5,s9,69a <vprintf+0xd6>
      } else if(c == 'x') {
 646:	07a78863          	beq	a5,s10,6b6 <vprintf+0xf2>
      } else if(c == 'p') {
 64a:	09b78463          	beq	a5,s11,6d2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 64e:	07300713          	li	a4,115
 652:	0ce78663          	beq	a5,a4,71e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 656:	06300713          	li	a4,99
 65a:	0ee78e63          	beq	a5,a4,756 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 65e:	11478863          	beq	a5,s4,76e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 662:	85d2                	mv	a1,s4
 664:	8556                	mv	a0,s5
 666:	00000097          	auipc	ra,0x0
 66a:	e92080e7          	jalr	-366(ra) # 4f8 <putc>
        putc(fd, c);
 66e:	85ca                	mv	a1,s2
 670:	8556                	mv	a0,s5
 672:	00000097          	auipc	ra,0x0
 676:	e86080e7          	jalr	-378(ra) # 4f8 <putc>
      }
      state = 0;
 67a:	4981                	li	s3,0
 67c:	b765                	j	624 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 67e:	008b0913          	addi	s2,s6,8
 682:	4685                	li	a3,1
 684:	4629                	li	a2,10
 686:	000b2583          	lw	a1,0(s6)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	e8e080e7          	jalr	-370(ra) # 51a <printint>
 694:	8b4a                	mv	s6,s2
      state = 0;
 696:	4981                	li	s3,0
 698:	b771                	j	624 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 69a:	008b0913          	addi	s2,s6,8
 69e:	4681                	li	a3,0
 6a0:	4629                	li	a2,10
 6a2:	000b2583          	lw	a1,0(s6)
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	e72080e7          	jalr	-398(ra) # 51a <printint>
 6b0:	8b4a                	mv	s6,s2
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	bf85                	j	624 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6b6:	008b0913          	addi	s2,s6,8
 6ba:	4681                	li	a3,0
 6bc:	4641                	li	a2,16
 6be:	000b2583          	lw	a1,0(s6)
 6c2:	8556                	mv	a0,s5
 6c4:	00000097          	auipc	ra,0x0
 6c8:	e56080e7          	jalr	-426(ra) # 51a <printint>
 6cc:	8b4a                	mv	s6,s2
      state = 0;
 6ce:	4981                	li	s3,0
 6d0:	bf91                	j	624 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6d2:	008b0793          	addi	a5,s6,8
 6d6:	f8f43423          	sd	a5,-120(s0)
 6da:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6de:	03000593          	li	a1,48
 6e2:	8556                	mv	a0,s5
 6e4:	00000097          	auipc	ra,0x0
 6e8:	e14080e7          	jalr	-492(ra) # 4f8 <putc>
  putc(fd, 'x');
 6ec:	85ea                	mv	a1,s10
 6ee:	8556                	mv	a0,s5
 6f0:	00000097          	auipc	ra,0x0
 6f4:	e08080e7          	jalr	-504(ra) # 4f8 <putc>
 6f8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6fa:	03c9d793          	srli	a5,s3,0x3c
 6fe:	97de                	add	a5,a5,s7
 700:	0007c583          	lbu	a1,0(a5)
 704:	8556                	mv	a0,s5
 706:	00000097          	auipc	ra,0x0
 70a:	df2080e7          	jalr	-526(ra) # 4f8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 70e:	0992                	slli	s3,s3,0x4
 710:	397d                	addiw	s2,s2,-1
 712:	fe0914e3          	bnez	s2,6fa <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 716:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 71a:	4981                	li	s3,0
 71c:	b721                	j	624 <vprintf+0x60>
        s = va_arg(ap, char*);
 71e:	008b0993          	addi	s3,s6,8
 722:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 726:	02090163          	beqz	s2,748 <vprintf+0x184>
        while(*s != 0){
 72a:	00094583          	lbu	a1,0(s2)
 72e:	c9a1                	beqz	a1,77e <vprintf+0x1ba>
          putc(fd, *s);
 730:	8556                	mv	a0,s5
 732:	00000097          	auipc	ra,0x0
 736:	dc6080e7          	jalr	-570(ra) # 4f8 <putc>
          s++;
 73a:	0905                	addi	s2,s2,1
        while(*s != 0){
 73c:	00094583          	lbu	a1,0(s2)
 740:	f9e5                	bnez	a1,730 <vprintf+0x16c>
        s = va_arg(ap, char*);
 742:	8b4e                	mv	s6,s3
      state = 0;
 744:	4981                	li	s3,0
 746:	bdf9                	j	624 <vprintf+0x60>
          s = "(null)";
 748:	00000917          	auipc	s2,0x0
 74c:	35090913          	addi	s2,s2,848 # a98 <malloc+0x20a>
        while(*s != 0){
 750:	02800593          	li	a1,40
 754:	bff1                	j	730 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 756:	008b0913          	addi	s2,s6,8
 75a:	000b4583          	lbu	a1,0(s6)
 75e:	8556                	mv	a0,s5
 760:	00000097          	auipc	ra,0x0
 764:	d98080e7          	jalr	-616(ra) # 4f8 <putc>
 768:	8b4a                	mv	s6,s2
      state = 0;
 76a:	4981                	li	s3,0
 76c:	bd65                	j	624 <vprintf+0x60>
        putc(fd, c);
 76e:	85d2                	mv	a1,s4
 770:	8556                	mv	a0,s5
 772:	00000097          	auipc	ra,0x0
 776:	d86080e7          	jalr	-634(ra) # 4f8 <putc>
      state = 0;
 77a:	4981                	li	s3,0
 77c:	b565                	j	624 <vprintf+0x60>
        s = va_arg(ap, char*);
 77e:	8b4e                	mv	s6,s3
      state = 0;
 780:	4981                	li	s3,0
 782:	b54d                	j	624 <vprintf+0x60>
    }
  }
}
 784:	70e6                	ld	ra,120(sp)
 786:	7446                	ld	s0,112(sp)
 788:	74a6                	ld	s1,104(sp)
 78a:	7906                	ld	s2,96(sp)
 78c:	69e6                	ld	s3,88(sp)
 78e:	6a46                	ld	s4,80(sp)
 790:	6aa6                	ld	s5,72(sp)
 792:	6b06                	ld	s6,64(sp)
 794:	7be2                	ld	s7,56(sp)
 796:	7c42                	ld	s8,48(sp)
 798:	7ca2                	ld	s9,40(sp)
 79a:	7d02                	ld	s10,32(sp)
 79c:	6de2                	ld	s11,24(sp)
 79e:	6109                	addi	sp,sp,128
 7a0:	8082                	ret

00000000000007a2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7a2:	715d                	addi	sp,sp,-80
 7a4:	ec06                	sd	ra,24(sp)
 7a6:	e822                	sd	s0,16(sp)
 7a8:	1000                	addi	s0,sp,32
 7aa:	e010                	sd	a2,0(s0)
 7ac:	e414                	sd	a3,8(s0)
 7ae:	e818                	sd	a4,16(s0)
 7b0:	ec1c                	sd	a5,24(s0)
 7b2:	03043023          	sd	a6,32(s0)
 7b6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7ba:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7be:	8622                	mv	a2,s0
 7c0:	00000097          	auipc	ra,0x0
 7c4:	e04080e7          	jalr	-508(ra) # 5c4 <vprintf>
}
 7c8:	60e2                	ld	ra,24(sp)
 7ca:	6442                	ld	s0,16(sp)
 7cc:	6161                	addi	sp,sp,80
 7ce:	8082                	ret

00000000000007d0 <printf>:

void
printf(const char *fmt, ...)
{
 7d0:	711d                	addi	sp,sp,-96
 7d2:	ec06                	sd	ra,24(sp)
 7d4:	e822                	sd	s0,16(sp)
 7d6:	1000                	addi	s0,sp,32
 7d8:	e40c                	sd	a1,8(s0)
 7da:	e810                	sd	a2,16(s0)
 7dc:	ec14                	sd	a3,24(s0)
 7de:	f018                	sd	a4,32(s0)
 7e0:	f41c                	sd	a5,40(s0)
 7e2:	03043823          	sd	a6,48(s0)
 7e6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7ea:	00840613          	addi	a2,s0,8
 7ee:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7f2:	85aa                	mv	a1,a0
 7f4:	4505                	li	a0,1
 7f6:	00000097          	auipc	ra,0x0
 7fa:	dce080e7          	jalr	-562(ra) # 5c4 <vprintf>
}
 7fe:	60e2                	ld	ra,24(sp)
 800:	6442                	ld	s0,16(sp)
 802:	6125                	addi	sp,sp,96
 804:	8082                	ret

0000000000000806 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 806:	1141                	addi	sp,sp,-16
 808:	e422                	sd	s0,8(sp)
 80a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 80c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 810:	00000797          	auipc	a5,0x0
 814:	2a87b783          	ld	a5,680(a5) # ab8 <freep>
 818:	a805                	j	848 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 81a:	4618                	lw	a4,8(a2)
 81c:	9db9                	addw	a1,a1,a4
 81e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 822:	6398                	ld	a4,0(a5)
 824:	6318                	ld	a4,0(a4)
 826:	fee53823          	sd	a4,-16(a0)
 82a:	a091                	j	86e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 82c:	ff852703          	lw	a4,-8(a0)
 830:	9e39                	addw	a2,a2,a4
 832:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 834:	ff053703          	ld	a4,-16(a0)
 838:	e398                	sd	a4,0(a5)
 83a:	a099                	j	880 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 83c:	6398                	ld	a4,0(a5)
 83e:	00e7e463          	bltu	a5,a4,846 <free+0x40>
 842:	00e6ea63          	bltu	a3,a4,856 <free+0x50>
{
 846:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 848:	fed7fae3          	bgeu	a5,a3,83c <free+0x36>
 84c:	6398                	ld	a4,0(a5)
 84e:	00e6e463          	bltu	a3,a4,856 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 852:	fee7eae3          	bltu	a5,a4,846 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 856:	ff852583          	lw	a1,-8(a0)
 85a:	6390                	ld	a2,0(a5)
 85c:	02059713          	slli	a4,a1,0x20
 860:	9301                	srli	a4,a4,0x20
 862:	0712                	slli	a4,a4,0x4
 864:	9736                	add	a4,a4,a3
 866:	fae60ae3          	beq	a2,a4,81a <free+0x14>
    bp->s.ptr = p->s.ptr;
 86a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 86e:	4790                	lw	a2,8(a5)
 870:	02061713          	slli	a4,a2,0x20
 874:	9301                	srli	a4,a4,0x20
 876:	0712                	slli	a4,a4,0x4
 878:	973e                	add	a4,a4,a5
 87a:	fae689e3          	beq	a3,a4,82c <free+0x26>
  } else
    p->s.ptr = bp;
 87e:	e394                	sd	a3,0(a5)
  freep = p;
 880:	00000717          	auipc	a4,0x0
 884:	22f73c23          	sd	a5,568(a4) # ab8 <freep>
}
 888:	6422                	ld	s0,8(sp)
 88a:	0141                	addi	sp,sp,16
 88c:	8082                	ret

000000000000088e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 88e:	7139                	addi	sp,sp,-64
 890:	fc06                	sd	ra,56(sp)
 892:	f822                	sd	s0,48(sp)
 894:	f426                	sd	s1,40(sp)
 896:	f04a                	sd	s2,32(sp)
 898:	ec4e                	sd	s3,24(sp)
 89a:	e852                	sd	s4,16(sp)
 89c:	e456                	sd	s5,8(sp)
 89e:	e05a                	sd	s6,0(sp)
 8a0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8a2:	02051493          	slli	s1,a0,0x20
 8a6:	9081                	srli	s1,s1,0x20
 8a8:	04bd                	addi	s1,s1,15
 8aa:	8091                	srli	s1,s1,0x4
 8ac:	0014899b          	addiw	s3,s1,1
 8b0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8b2:	00000517          	auipc	a0,0x0
 8b6:	20653503          	ld	a0,518(a0) # ab8 <freep>
 8ba:	c515                	beqz	a0,8e6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8be:	4798                	lw	a4,8(a5)
 8c0:	02977f63          	bgeu	a4,s1,8fe <malloc+0x70>
 8c4:	8a4e                	mv	s4,s3
 8c6:	0009871b          	sext.w	a4,s3
 8ca:	6685                	lui	a3,0x1
 8cc:	00d77363          	bgeu	a4,a3,8d2 <malloc+0x44>
 8d0:	6a05                	lui	s4,0x1
 8d2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8d6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8da:	00000917          	auipc	s2,0x0
 8de:	1de90913          	addi	s2,s2,478 # ab8 <freep>
  if(p == (char*)-1)
 8e2:	5afd                	li	s5,-1
 8e4:	a88d                	j	956 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8e6:	00000797          	auipc	a5,0x0
 8ea:	1da78793          	addi	a5,a5,474 # ac0 <base>
 8ee:	00000717          	auipc	a4,0x0
 8f2:	1cf73523          	sd	a5,458(a4) # ab8 <freep>
 8f6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8f8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8fc:	b7e1                	j	8c4 <malloc+0x36>
      if(p->s.size == nunits)
 8fe:	02e48b63          	beq	s1,a4,934 <malloc+0xa6>
        p->s.size -= nunits;
 902:	4137073b          	subw	a4,a4,s3
 906:	c798                	sw	a4,8(a5)
        p += p->s.size;
 908:	1702                	slli	a4,a4,0x20
 90a:	9301                	srli	a4,a4,0x20
 90c:	0712                	slli	a4,a4,0x4
 90e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 910:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 914:	00000717          	auipc	a4,0x0
 918:	1aa73223          	sd	a0,420(a4) # ab8 <freep>
      return (void*)(p + 1);
 91c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 920:	70e2                	ld	ra,56(sp)
 922:	7442                	ld	s0,48(sp)
 924:	74a2                	ld	s1,40(sp)
 926:	7902                	ld	s2,32(sp)
 928:	69e2                	ld	s3,24(sp)
 92a:	6a42                	ld	s4,16(sp)
 92c:	6aa2                	ld	s5,8(sp)
 92e:	6b02                	ld	s6,0(sp)
 930:	6121                	addi	sp,sp,64
 932:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 934:	6398                	ld	a4,0(a5)
 936:	e118                	sd	a4,0(a0)
 938:	bff1                	j	914 <malloc+0x86>
  hp->s.size = nu;
 93a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 93e:	0541                	addi	a0,a0,16
 940:	00000097          	auipc	ra,0x0
 944:	ec6080e7          	jalr	-314(ra) # 806 <free>
  return freep;
 948:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 94c:	d971                	beqz	a0,920 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 94e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 950:	4798                	lw	a4,8(a5)
 952:	fa9776e3          	bgeu	a4,s1,8fe <malloc+0x70>
    if(p == freep)
 956:	00093703          	ld	a4,0(s2)
 95a:	853e                	mv	a0,a5
 95c:	fef719e3          	bne	a4,a5,94e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 960:	8552                	mv	a0,s4
 962:	00000097          	auipc	ra,0x0
 966:	b76080e7          	jalr	-1162(ra) # 4d8 <sbrk>
  if(p == (char*)-1)
 96a:	fd5518e3          	bne	a0,s5,93a <malloc+0xac>
        return 0;
 96e:	4501                	li	a0,0
 970:	bf45                	j	920 <malloc+0x92>
