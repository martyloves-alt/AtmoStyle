package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import coil.compose.AsyncImage
import com.example.ui.theme.MyApplicationTheme
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    enableEdgeToEdge()
    setContent {
      MyApplicationTheme {
        val navController = rememberNavController()
        NavHost(navController = navController, startDestination = "startup") {
          composable("startup") {
            StartupScreen(navController = navController)
          }
          composable("lookbook") {
            LookbookScreen(navController = navController)
          }
          composable("settings") {
            SettingsScreen(navController = navController)
          }
          composable("checkout") {
            CheckoutScreen(navController = navController)
          }
        }
      }
    }
  }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun StartupScreen(navController: NavController) {
  // "Zéro Blabla" Startup Screen
  var currentQuestionIndex by remember { mutableIntStateOf(0) }
  var isGenerating by remember { mutableStateOf(false) }

  val questions = listOf(
    "Préférence textile de base :" to listOf("Bazin", "Wax", "Chemise + Pantalon classique"),
    "Contexte de la journée :" to listOf("Visite de patients", "Formation magistrale", "Dîner privé"),
    "Accessoire clé :" to listOf("Montre à mouvement automatique visible", "Poignet dégagé", "Bracelet discret"),
    "Signature olfactive suggérée :" to listOf("Notes de propre/savonneux", "Fraîcheur neutre", "Boisé intense")
  )

  LaunchedEffect(isGenerating) {
    if (isGenerating) {
      delay(2000) // Simulate AI Generation
      navController.navigate("lookbook") {
        popUpTo("startup") { inclusive = true }
      }
    }
  }

  Scaffold(
    containerColor = MaterialTheme.colorScheme.background,
    modifier = Modifier.fillMaxSize()
  ) { innerPadding ->
    Box(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
        .padding(24.dp),
      contentAlignment = Alignment.Center
    ) {
      if (isGenerating) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
          CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
          Spacer(modifier = Modifier.height(24.dp))
          Text(
            text = "Génération du style en cours...",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onBackground
          )
        }
      } else {
        Column(
          modifier = Modifier.fillMaxWidth(),
          verticalArrangement = Arrangement.Center
        ) {
          val (question, answers) = questions[currentQuestionIndex]
          
          Text(
            text = question,
            style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Light),
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(bottom = 32.dp)
          )

          FlowRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.fillMaxWidth()
          ) {
            answers.forEach { answer ->
              PillButton(text = answer) {
                if (currentQuestionIndex < questions.size - 1) {
                  currentQuestionIndex++
                } else {
                  isGenerating = true
                }
              }
            }
          }
        }
      }
      
      // Top right settings icon
      IconButton(
        onClick = { navController.navigate("settings") },
        modifier = Modifier.align(Alignment.TopEnd)
      ) {
        Icon(
          imageVector = Icons.Default.Settings,
          contentDescription = "Réglages",
          tint = MaterialTheme.colorScheme.onBackground
        )
      }
    }
  }
}

@Composable
fun PillButton(text: String, onClick: () -> Unit) {
  Box(
    modifier = Modifier
      .clip(RoundedCornerShape(50))
      .background(MaterialTheme.colorScheme.surface)
      .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(50))
      .clickable(onClick = onClick)
      .padding(horizontal = 20.dp, vertical = 12.dp)
      .testTag("pill_$text")
  ) {
    Text(
      text = text,
      style = MaterialTheme.typography.bodyMedium,
      color = MaterialTheme.colorScheme.onBackground
    )
  }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LookbookScreen(navController: NavController) {
  Scaffold(
    containerColor = MaterialTheme.colorScheme.background,
    topBar = {
      TopAppBar(
        title = { Text("Météo-Style", fontWeight = FontWeight.Bold) },
        colors = TopAppBarDefaults.topAppBarColors(
          containerColor = Color.Transparent,
          titleContentColor = MaterialTheme.colorScheme.primary,
          actionIconContentColor = MaterialTheme.colorScheme.onBackground
        ),
        actions = {
          IconButton(onClick = { navController.navigate("settings") }) {
            Icon(Icons.Default.Settings, contentDescription = "Réglages")
          }
        }
      )
    },
    bottomBar = {
      Box(modifier = Modifier
        .fillMaxWidth()
        .padding(24.dp)) {
        Button(
          onClick = { navController.navigate("checkout") },
          colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
          modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .testTag("checkout_button"),
          shape = RoundedCornerShape(12.dp)
        ) {
          Text("Shop the look", color = MaterialTheme.colorScheme.onPrimary, fontWeight = FontWeight.Bold)
        }
      }
    }
  ) { innerPadding ->
    Box(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
    ) {
      // Fake realistic image of an African outfit in Paris/European setting
      // Using an unsplash image for demonstration
      AsyncImage(
        model = "https://images.unsplash.com/photo-1520975954732-57dd22299614?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
        contentDescription = "Look généré",
        modifier = Modifier.fillMaxSize(),
        contentScale = ContentScale.Crop
      )
      
      // Gradient overlay for text readability at the bottom
      Box(
        modifier = Modifier
          .fillMaxSize()
          .background(
            androidx.compose.ui.graphics.Brush.verticalGradient(
              colors = listOf(Color.Transparent, MaterialTheme.colorScheme.background.copy(alpha = 0.9f)),
              startY = 500f
            )
          )
      )

      Column(
        modifier = Modifier
          .align(Alignment.BottomStart)
          .padding(24.dp)
          .padding(bottom = 60.dp) // space for button
      ) {
        Text(
          text = "Aujourd'hui : 24°C, Averses",
          style = MaterialTheme.typography.bodyLarge,
          color = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
          text = "Veste croisée européenne, touches de Wax, bottines imperméables.",
          style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Medium),
          color = MaterialTheme.colorScheme.onBackground
        )
      }
    }
  }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(navController: NavController) {
  var pushEnabled by remember { mutableStateOf(true) }

  Scaffold(
    containerColor = MaterialTheme.colorScheme.background,
    topBar = {
      TopAppBar(
        title = { Text("Réglages", fontWeight = FontWeight.Medium) },
        colors = TopAppBarDefaults.topAppBarColors(
          containerColor = Color.Transparent,
          titleContentColor = MaterialTheme.colorScheme.onBackground
        )
      )
    }
  ) { innerPadding ->
    Column(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
        .padding(24.dp)
    ) {
      Text(
        text = "Notifications Proactives",
        style = MaterialTheme.typography.titleLarge,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(bottom = 24.dp)
      )

      Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
      ) {
        Column(modifier = Modifier.weight(1f)) {
          Text(
            text = "Alertes de la veille",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onBackground
          )
          Text(
            text = "Recevoir la suggestion de tenue tous les soirs à 20h00 en fonction de la météo de demain.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp, end = 16.dp)
          )
        }
        Switch(
          checked = pushEnabled,
          onCheckedChange = { pushEnabled = it },
          colors = SwitchDefaults.colors(
            checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
            checkedTrackColor = MaterialTheme.colorScheme.primary,
            uncheckedThumbColor = MaterialTheme.colorScheme.onSurfaceVariant,
            uncheckedTrackColor = MaterialTheme.colorScheme.surfaceVariant
          )
        )
      }
      
      Spacer(modifier = Modifier.height(48.dp))
      
      Button(
        onClick = { navController.popBackStack() },
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
      ) {
        Text("Retour", color = MaterialTheme.colorScheme.onBackground)
      }
    }
  }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckoutScreen(navController: NavController) {
  Scaffold(
    containerColor = MaterialTheme.colorScheme.background,
    topBar = {
      TopAppBar(
        title = { Text("Sur-Mesure", fontWeight = FontWeight.Medium) },
        colors = TopAppBarDefaults.topAppBarColors(
          containerColor = Color.Transparent,
          titleContentColor = MaterialTheme.colorScheme.onBackground
        )
      )
    }
  ) { innerPadding ->
    Column(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
        .padding(24.dp),
      horizontalAlignment = Alignment.CenterHorizontally,
      verticalArrangement = Arrangement.Center
    ) {
      Icon(
        imageVector = Icons.Default.Check,
        contentDescription = "Success",
        tint = MaterialTheme.colorScheme.primary,
        modifier = Modifier.size(64.dp)
      )
      Spacer(modifier = Modifier.height(24.dp))
      Text(
        text = "Demande envoyée aux ateliers.",
        style = MaterialTheme.typography.headlineSmall,
        color = MaterialTheme.colorScheme.onBackground,
        textAlign = TextAlign.Center
      )
      Spacer(modifier = Modifier.height(16.dp))
      Text(
        text = "Vos mensurations sont à jour. L'assemblage des textiles Bazin/Wax avec la coupe croisée européenne a été commandé.",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center
      )
      
      Spacer(modifier = Modifier.height(48.dp))
      
      Button(
        onClick = { navController.popBackStack("startup", inclusive = false) },
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
        modifier = Modifier
          .fillMaxWidth()
          .height(56.dp),
        shape = RoundedCornerShape(12.dp)
      ) {
        Text("Nouveau Look", color = MaterialTheme.colorScheme.onPrimary, fontWeight = FontWeight.Bold)
      }
    }
  }
}
