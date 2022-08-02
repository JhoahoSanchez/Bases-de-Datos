/* 1. Escriba un SP para realizar una transferencia entre cuentas. El SP recibe como parámetros: el número de cuenta de origen, 
el valor a debitar de esa cuenta, el número de cuenta de destino. (Usar el saldo_contable en cuenta origen y en cuenta destino). 
Tome como fecha del movimiento  la fecha del sistema. Debe considerar que la transferencia genera un DETALLE_MOV de  débito de la 
cuenta origen y otro de crédito en la cuenta destino. Además, verifique si la cuenta de origen tiene el saldo suficiente, en caso 
contrario rollback. Si hay algún error, rollback a la transacción. La transferencia debe tratarse como  una transacción para considerar 
el commit y el rollback respectivos */

USE BANCO;
SELECT * FROM CUENTAS WHERE NUMCTA=1 OR NUMCTA=15;
SELECT * FROM DETALLE_MOV_CTA WHERE NUMCTA=1 OR NUMCTA=15;

CREATE PROCEDURE SP_01
@CUENTA_ORIGEN INT,
@VALOR_TRAN MONEY,
@CUENTA_DESTINO INT
AS
IF NOT EXISTS(SELECT * FROM Cuentas WHERE numCta=@CUENTA_ORIGEN)
		BEGIN
			PRINT 'LA CUENTA DE ORIGEN NO EXISTE';
			RETURN(1);
		END
ELSE
		BEGIN
			IF NOT EXISTS(SELECT * FROM CUENTAS WHERE NUMCTA=@CUENTA_DESTINO)
			BEGIN
				PRINT 'LA CUENTA DE DESTINO NO EXISTE';
				RETURN(2);
			END
			ELSE
			BEGIN
				IF EXISTS (SELECT * FROM CUENTAS WHERE NUMCTA=@CUENTA_ORIGEN AND SALDO_EFECTIVO > @VALOR_TRAN)
				BEGIN
					UPDATE CUENTAS SET SALDO_EFECTIVO = SALDO_EFECTIVO - @VALOR_TRAN 
					WHERE NUMCTA=@CUENTA_ORIGEN;

					UPDATE CUENTAS SET SALDO_EFECTIVO = SALDO_EFECTIVO + @VALOR_TRAN 
					WHERE NUMCTA=@CUENTA_DESTINO;

					INSERT INTO DETALLE_MOV_CTA ([numCta],[fecha_Mov],[tipo_Mov],[valor]) 
					VALUES(@CUENTA_ORIGEN, GETDATE(),'D',@VALOR_TRAN);

					INSERT INTO DETALLE_MOV_CTA ([numCta],[fecha_Mov],[tipo_Mov],[valor]) 
					VALUES(@CUENTA_DESTINO, GETDATE(),'C',@VALOR_TRAN);

					PRINT 'LA TRANSACCION SE REALIZO CON EXITO'
				END
				ELSE
				BEGIN
					PRINT 'EL SALDO EFECTIVO DE LA CUENTA DE ORIGEN ES INSUFICIENTE PARA REALIZAR ESTA TRANSACCION'
					RETURN (3)
				END
			END
			
		END
GO

BEGIN TRAN
	BEGIN TRY
		EXEC SP_01 1,20.00,15
		PRINT 'LA TRANSACCION SE COMPLETO'
		COMMIT TRAN
	END TRY
	BEGIN CATCH
	 ROLLBACK TRAN
	 PRINT 'LA TRANSACCION FALLO'
	END CATCH
SELECT * FROM CUENTAS WHERE NUMCTA=1 OR NUMCTA=15;
SELECT * FROM DETALLE_MOV_CTA WHERE NUMCTA=1 OR NUMCTA=15;

/*3. Sobre la BD BANCO. Escriba un SP que verifique un préstamo que ya ha sido cancelado. 
El SP recibe como parámetro el número del préstamo.

b. Verifique que el préstamo tenga saldo cero. Si no lo tiene, ROLLBACK.
c. Verifique si la suma del campo VALOR en detalle_préstamo, es igual al MONTO del préstamo, 
si no lo es imprima un mensaje y haga un ROLLBACK. 
d. Si se cumple, pase el registro de PRESTAMO a una tabla idèntica (previamente creada) 
que se llame PRESTAMOS_CANCELADOS y pase los registros de DETALLE_PRESTAMO a una tabla idéntica  
(previamente creada) que se llame DETALLE_PRESTAMO_CANCELADOS.  
e. Luego borre los registros de DETALLE_PRESTAMO y de PRESTAMOS. */

USE BANCO
GO

SELECT * FROM PRESTAMOS;
SELECT * FROM DETALLE_PRESTAMO;
GO

CREATE TABLE PRESTAMOS_CANCELADOS
(NUM_PRESTAMO INT PRIMARY KEY, MONTO MONEY, FECHA DATETIME, DIVIDENDOS INT, SALDO MONEY, CODSUCURSAL INT, CODCLIENTE INT)

SELECT * FROM PRESTAMOS_CANCELADOS;
DROP TABLE PRESTAMOS_CANCELADOS;
GO

CREATE TABLE DETALLE_PRESTAMOS_CANCELADOS
(NUM_DETALLE_PRES INT PRIMARY KEY, FECHA_PAGO DATETIME, VALOR MONEY, NUM_PRESTAMO INT)

SELECT * FROM DETALLE_PRESTAMOS_CANCELADOS;
DROP TABLE DETALLE_PRESTAMOS_CANCELADOS;
GO


DROP PROCEDURE SP_03
GO

CREATE PROCEDURE SP_03
@NUM_PRESTAMO INT, 
@SUMA_VALOR MONEY 
AS
SET @SUMA_VALOR = (SELECT SUM(VALOR) FROM DETALLE_PRESTAMO WHERE NUMPRESTAMO = @NUM_PRESTAMO)

SELECT * FROM PRESTAMOS
IF NOT EXISTS (SELECT NUMPRESTAMO FROM PRESTAMOS WHERE NUMPRESTAMO = @NUM_PRESTAMO)
	BEGIN
		PRINT 'EL NÚMERO DE PRÉSTAMO NO EXISTE'
		RETURN(0);
	END

ELSE
	BEGIN
		SELECT * FROM PRESTAMOS
		IF NOT EXISTS (SELECT NUMPRESTAMO FROM PRESTAMOS WHERE SALDO = 0)
			BEGIN
				PRINT 'EL NÚMERO DE PRÉSTAMO NO HA SIDO CANCELADO AÚN.'

			IF @SUMA_VALOR != (SELECT MONTO FROM PRESTAMOS WHERE NUMPRESTAMO = @NUM_PRESTAMO)
				BEGIN 
					PRINT 'ERROR: LOS PAGOS NO SON IGUALES AL MONTO DEL PRÉSTAMO.'
					RETURN(0);
				END
			END
		ELSE
			BEGIN
				INSERT INTO PRESTAMOS_CANCELADOS
				SELECT * FROM PRESTAMOS WHERE NUMPRESTAMO = @NUM_PRESTAMO

				INSERT INTO DETALLE_PRESTAMOS_CANCELADOS
				SELECT * FROM DETALLE_PRESTAMO WHERE NUMPRESTAMO = @NUM_PRESTAMO

				DELETE DETALLE_PRESTAMO WHERE NUMPRESTAMO = @NUM_PRESTAMO

				DELETE PRESTAMOS WHERE NUMPRESTAMO = @NUM_PRESTAMO

				PRINT 'LA TRANSACCION SE REALIZO CON ÉXITO.'
			 END
	END
GO


BEGIN TRAN
	BEGIN TRY
		EXEC SP_03 2, 3200
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
	END CATCH
GO

SELECT * FROM PRESTAMOS;
SELECT * FROM DETALLE_PRESTAMO;

SELECT * FROM PRESTAMOS_CANCELADOS;
SELECT * FROM DETALLE_PRESTAMOS_CANCELADOS;

/* 4. Escriba un SP para obtener la estadística de venta de un producto, que reciba como parámetro una 
variable @productoid int y asigne un id de producto.    
•	Si no existe ese producto, imprima un mensaje y retorne un código de error.  
•	Si existe el producto, pero no se tienen ventas de ese producto,    imprima un mensaje con código de error.
•	Para obtener la estadística verifique el número de órdenes que se tienen y en cuántas    de esas órdenes 
se ha incluido ese producto y lo presenta como porcentaje.  (ej.  50 órdenes, 20 órdenes con ese producto,
20/50 *100). Retorne esa estadística (un valor decimal    entre 0 y 100, como un parámetro de salida. */

use PEDIDOS
go

select * from PRODUCTOS;
select * from DETALLE_ORDENES;

select COUNT(*) from ORDENES;

drop procedure SP_04;

create procedure SP_04 @productoid int, @porcentaje decimal OUTPUT
as

if not EXISTS(select PRODUCTOID from PRODUCTOS where PRODUCTOID = @productoid)
	begin
		print 'ERROR: El codigo de producto ingresado no existe'
		return(1)
	end
else
	begin
		if not EXISTS(select cantidad from DETALLE_ORDENES where PRODUCTOID = @productoid)
			begin
				print 'ERROR: No existen ventas de este producto'
				return(2)
			end
	end

declare @numOrdenes int, @numOrdenesConProducto int

set @numOrdenes = (select COUNT(*) from ORDENES);
set @numOrdenesConProducto = (select COUNT(PRODUCTOID) from DETALLE_ORDENES where PRODUCTOID = @productoid);
set @porcentaje = (convert(decimal(5,2), @numOrdenesConProducto)/convert(decimal(5,2), @numOrdenes))*100.0;

print CONVERT(varchar(2), @numOrdenes) + ' ordenes, ' + CONVERT(varchar(2), @numOrdenesConProducto) 
	+ ' ordenes con ese producto, Porcentaje: ' + CONVERT(varchar(10), @porcentaje) +'%'
return(0)
go

declare @id int, @per decimal(5,2), @retorno int;
set @id = 1;
execute @retorno = SP_04 @id, @per OUTPUT;

print 'Retorno de sp: ' + convert(varchar(2),@retorno);
print 'Valor output: '+ convert(varchar(8),@per);

