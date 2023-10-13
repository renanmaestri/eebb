# (PART) PARTE III - Morfometria Geométrica {.unnumbered}

# Morfometria Geométrica

"Organismos são entidades integradas, e não coleções de objetos discretos" @gould1979.

A visão "atomista" dos organismos, que trata medidas lineares únicas como merecedoras de atenção particular, está errada do ponto de vista da genética e do desenvolvimento. A evolução morfológica é inerentemente multivarida. Por isso, precisamos usar ferramentas multivariadas para entender os processos biológicos que produzem morfologias distintas. A morfometria fornece maneiras quantitativas de comparar a forma dos organismos, obtidas a partir do uso de ferramentas matemáticas sobre matrizes de variáveis contínuas. Assim, a morfometria multivariada é a melhor maneira de entender morfogênese e evolução morfológica.

Contudo, a morfometria tradicional não oferece uma maneira precisa para acessar a geometria dos organismos, já que carece de uma definição precisa de forma e, assim, não distingue claramente forma e tamanho. Além disso, a morfometria tradicional não oferece maneiras de visualizar e interpretar com facilidade as diferenças morfológicas que estamos tentando entender.

Ferramentas de **morfometria geométrica** oferecem uma *descrição precisa e acurada* da forma (geometria) dos organismos, podem ser combinadas com *análises estatísticas* rigorosas, e nos permitem *visualizar* as diferenças de **forma** entre organismos com extrema facilidade, o que não é alcançado facilmente por outros métodos @zelditch2012.

**Forma**, em morfometria geométrica, é formamente definida como *todas as características geométricas de uma configuração de pontos exceto por seu tamanho, posição e orientação* [@kendall; @bookstein1989; @dryden1998; @monteiro1999; @klingenberg2016]. Essa formalidade é capturada matematicamente pela técnica conhecida como *Análise Generalizada de Procrustes*, que veremos na sequência. Assim, *morfometria geométrica faz uma distinção entre tamanho e forma*. *Tamanho* pode ser resumido em um número que captura a dimensão ou escala geral de um objeto @klingenberg2016 - veja a seção do manual sobre Tamanho do Centróide. *Forma* captura as diferentes proporções de um objeto: as formas de dois objetos podem ser iguais se forem geométricamente idênticas, mesmo que seu tamanho seja diferente [@zelditch2012; @klingenberg2016].

Os **landmarks**, ou marcos anatômicos, são pontos anatômicos discretos, fudamentais em morfometria, que precisam ser reconhecíveis em todos os indivíduos/objetos da amostra. A definição dos landmarks é central, já que eles permitirão capturar as estruturas biológicas de interesse (entre os landmarks) e comparar essas estruturas entre organismos. Daí a importância de os landmarks serem homólogos entre os indivíduos no estudo. Em morfometria geométrica, as **coordenadas cartesianas** desses landmarks é que serão usadas nas análises. Há uma outra vantagem da morfometria geométrica que resulta do uso dessas coordenadas cartesianas ao invés do uso de medidas lineares entre landmarks. A análise das variáveis de forma, obtidas por morfometria geométrica, sobre determinado número N de landmarks, contém tanta informação de forma quanto teriam todas as medidas lineares entre os N pares de landmarks, e com um número muito menor de variáveis de forma, removendo a redundância que existiria na matriz de medidas lineares entre os N landmarks.

Além dos landmarks, também podem ser utilizados semilandmarks ou análises de contorno quando a estrutura biológica for muito complexa para ser inteiramente capturada por landmarks e/ou quando landmarks não puderem ser localizados com confiabilidade. Veja a seção sobre semilandmarks.

Para livros abrangentes sobre morfometria geométrica, veja: @monteiro1999 e @zelditch2012.

\pagebreak
