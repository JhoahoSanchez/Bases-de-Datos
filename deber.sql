/* 5. Escriba un SP para obtener la estadística de venta de un producto, que reciba como parámetro una 
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

drop procedure estadisticas_de_ventas;

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

