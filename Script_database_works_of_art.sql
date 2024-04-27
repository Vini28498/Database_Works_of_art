/* Autor: Vinícius Henrique de Oliveira
	Data: 13/05/2023 

-- language: sql

/* Criando as tabelas do esquema físico*/
create table artista (
codart int not null,
nome char(40) not null,
qtd_obras_vendidas int not null,
primary key (codart)
)

create table loja (
codloja int not null,
nome char(40) not null,
endereco char(60) not null,
primary key (codloja)
)

create table obras_arte (
codobra int not null,
nome char(40) not null,
preco money not null,
tipo int not null,
codart int not null,
primary key (codobra),
foreign key (codart) references artista
)

create index ixobras_artista on obras_arte(codart)

create table escultura (
codobra int not null,
tecnica char(20) not null,
material char(20) null,
primary key (codobra),
foreign key (codobra) references obras_arte
)

create table pintura (
codobra int not null,
estilo char(20) not null,
recurso char(20) null,
primary key (codobra),
foreign key (codobra) references obras_arte
)

create table venda (
idvenda int not null,
data date not null,
comissao money null,
codloja int not null,
codobra int not null,
primary key (idvenda),
foreign key (codloja) references loja,
foreign key (codobra) references obras_arte
)

create unique index ix_venda_obra on venda(codobra)

create index ixvenda_loja on venda(codloja)

/* Visualizando as tabelas */
select *
from espbd.dbo.artista

select *
from espbd.dbo.loja

select *
from espbd.dbo.obras_arte

select *
from espbd.dbo.escultura

select *
from espbd.dbo.pintura

select *
from espbd.dbo.venda

/* Criando a View */
create view vendas_obras_tipo_escultura
as
select  espbd.dbo.venda."data",
		espbd.dbo.venda.codloja,
		espbd.dbo.obras_arte.nome,
		espbd.dbo.artista.nome as artista,
		espbd.dbo.obras_arte.preco
from espbd.dbo.obras_arte inner join escultura						/* Filtrando todas as obras de arte do tipo escutura, através de um relacionamento com a tabela "escultura". */
	on espbd.dbo.obras_arte.codobra = espbd.dbo.escultura.codobra
	inner join venda												/* Filtrando todas as obras de arte que contém vendas, através de um relacionamento com a tabela "venda". */	
	on espbd.dbo.escultura.codobra = espbd.dbo.venda.codobra
	inner join artista												/* Trazendo a informação do nome do artista, através de um relacionamento com a tabela "artista". */
	on espbd.dbo.obras_arte.codart = espbd.dbo.artista.codart;

/* Exemplo de consulta */
select *
from espbd.dbo.vendas_obras_tipo_escultura

/* Criando Stored Procedure */
create procedure ins_pintura
@codobra int,
@nome char(40),
@preco money,
@estilo char(20),
@recurso char(20),
@codart int
as
begin transaction
declare @retorno int

if exists (select 1 from artista where codart = @codart)
begin
  insert into obras_arte (codobra, nome, preco, tipo, codart)
  values (@codobra, @nome, @preco, 2, @codart)

  if @@rowcount > 0 /* Inserção de obra de arte bem sucedida */
  begin
    insert into pintura (codobra, estilo, recurso)
    values (@codobra, @estilo, @recurso)

    if @@rowcount > 0 /* Inserção de pintura bem sucedida */
    begin
      set @retorno = 1
      commit transaction
    end
    else
    begin
      set @retorno = 0
      rollback transaction
    end
  end
  else
  begin
    set @retorno = 0
    rollback transaction
  end
end
else
begin
  set @retorno = 0
  rollback transaction
end

return @retorno

/* Exemplo de execução */
declare @ret int
exec @ret = ins_pintura 1, 'Mona Lisa', 1000, 'Renascentista', 'Tinta a óleo', 1
print @ret
