      subroutine avrtau(xln,ylt,mig)
      parameter(timesm4=12.,timesm=12.,RAVR=100.e3)
c--------- This subr. is called from WIND in phase4 (mig=0)
c---------         and from atmos2ocean.f (mig=1) in coupled run
      include 'comblk.h'
      include 'TVARY.h'
      REAL LATMIN,LATMAX,LONGMIN,LONGMAX
      COMMON/sphere/REARTH,LATMIN,LATMAX,LONGMIN,LONGMAX
      real xln,ylt,tavr,counter,x1,y1,x0,y0,r,deltax,deltay
      real xlnc,yltc,tauavrp,taumaxp
      real tauavr,taumax,awucon,bwucon
      real RAVR,RRCT,xrct,yrct
      integer irct,jrct
      integer migtau
c
c------------- in comblk.h included common/tau/
c------------- also the next 5 parameters incuded in RST file
c     common/tau/ tauavr,taumax,awucon,bwucon,migtau
c-------------
      if(mig.eq.1) then
       print *,'begin avrtau: couped model'
      else
       print *,'begin avrtau: phase4'
      end if
c-------------
c
c     write(6,201) LATMIN,LATMAX,LONGMIN,LONGMAX
 201  format('avrtau: LATMIN,LATMAX,LONGMIN,LONGMAX=',4f7.2)
c
      pi=3.1415927
c------- save previous tauavr, taumax
      tauavrp=tauavr
      taumaxp=taumax
c-------  for coupled run use TC position from TVARY.h
c-------  for phase4 run use TC position: (xln,ylt)
      if(mig.eq.1) then
       xlnc=poslon
       yltc=poslat
      else
       xlnc=xln
       yltc=ylt
      end if
c
      tavr=0.0
      counter=0.0
      taumax=0.0
      RRCT=1.e8
      irct=1000
      jrct=1000
      do j=1,jm
       do i=1,im
        x1=(LONGMIN+float(I-1)*(LONGMAX-LONGMIN)/float(IM-1))*pi/180.
        y1=(LATMIN+float(J-1)*(LATMAX-LATMIN)/float(JM-1))*pi/180.
        x0=xlnc*pi/180.
        y0=yltc*pi/180.
        DELTAX=REARTH*COS(y0)*(x1-x0)
        DELTAY=REARTH*(y1-y0)
        r=SQRT(DELTAX**2+DELTAY**2)
        if(r.lt.RAVR) then
          tauabs=sqrt(wusurf(i,j)**2+wvsurf(i,j)**2)
          if(tauabs*fsm(i,j).gt.taumax) taumax=tauabs
          tavr=tavr+tauabs*fsm(i,j)
          counter=counter+fsm(i,j)
        end if
        if(r.lt.RRCT) then
         RRCT=r
         irct=i
         jrct=j
         xrct=x1*180./pi
         yrct=y1*180./pi
        end if
       end do
      end do
      if(counter.gt.0.) then
        tauavr=tavr/counter
      else
        tauavr=0.0
      end if
c
      if(mig.eq.1.and.migtau.eq.0) then
c--------- falk 08-19-03 use taumax instead of tauavr
c      if(tauavr.gt.tauavrp) then
c       awucon=tauavrp/tauavr
c       bwucon=(tauavr-tauavrp)/tauavr
       if(taumax.gt.taumaxp) then
        awucon=taumaxp/taumax
        bwucon=(taumax-taumaxp)/taumax
       else
        awucon=1.
        bwucon=0.
       end if
c-------------
       print *,' avrtau: first step in coupled model'
       print *,'migtau,mig=',migtau,mig
       write(6,101) tauavrp,tauavr,awucon,bwucon
 101   format(' tauavrp,tauavr,awucon,bwucon=',4(1PE10.2))
c-------------
       migtau=1
      end if
c
      if(mig.eq.1) then
       wucon=awucon+SIN(time*24./timesm*pi*0.5)*bwucon
       if(time*24..gt.timesm) wucon=1.
      else
       wucon=SIN(time*24./timesm4*pi*0.5)
       if(time*24..gt.timesm4) wucon=1.
      end if
c
      do j=1,jm
        do i=1,im
         wusurf(i,j)=wusurf(i,j)*wucon
         wvsurf(i,j)=wvsurf(i,j)*wucon
         taux(i,j)=taux(i,j)*wucon
         tauy(i,j)=tauy(i,j)*wucon
        end do
      end do
c-------------
c----------- falk 09-12-05 change output
      if(MOD(IINT,24).EQ.0) then
      if(mig.eq.1) then
       print *,'avrtau: couped model'
      else
       print *,'avrtau: phase4'
      end if
c-------------
      write(6,102) time*24,xlnc,yltc
 102  format('time*24,xlnc,yltc=',3f7.2)
      print *,'closest point to the center'
      write(6,204) xrct,yrct,RRCT,irct,jrct
 204  format('xrct,yrct,RRCT,irct,jrct=',2f7.2,f10.0,2i7)
      write(6,103) tauavrp,tauavr,taumaxp,taumax
 103  format('tauavrp,tauavr,taumaxp,taumax=',4(1PE10.2))
      write(6,202) awucon,bwucon,wucon
 202  format('  awucon,bwucon,wucon=',3f10.4)
c     write(6,203) timesm4,timesm
 203  format(   'timesm4,timesm=',2f7.2)
c-------------
      end if
      return
      end
c
c------------------- falk 06-21-05 use new SST assimilation procedure
c
